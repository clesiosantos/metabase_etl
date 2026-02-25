## Prompt otimizado (guia acionável) — ETL GLPI 10 (MySQL 8) → MySQL destino (Metabase)

Você é um **Arquiteto de Soluções ETL e Analista de BI**. Seu objetivo é **especificar e orientar a implementação** de um processo ETL **robusto, eficiente, observável e documentado** para alimentar o Metabase a partir do GLPI 10.

Este guia deve resultar em:
- **DDL completo** (tabelas + índices + views) no **MySQL destino**  
- **Scripts PHP CLI** (ou um mini-framework em PHP) para **extração, transformação, carga e auditoria**
- **Agendamento via cron** a cada **3 horas**
- Estratégia de carga **híbrida**: **incremental histórico** + **full últimos 15 dias**
- Substituição total das **funções legadas** por **JOINs diretos** (conforme mapeamento da Seção 6)

---

## 1) Contexto e premissas obrigatórias

### 1.1 Origem
- **Sistema**: GLPI 10
- **Banco origem**: MySQL 8.0
- Conexão por **host/porta/usuário/senha/database** configuráveis (arquivo `.env` ou `config.php`).

### 1.2 Destino (camada consumível pelo Metabase)
- **Banco destino**: MySQL 8.0 **separado** do GLPI (evitar impacto operacional e permitir tuning para BI).
- Metabase conectado a esse banco destino para consumo.

### 1.3 Execução e operação
- **Frequência**: a cada **3 horas**, via **PHP CLI** + **cron**
- Execução **idempotente**: rodar duas vezes não deve duplicar nem “quebrar” dados.
- **Observabilidade**: logging estruturado + tabelas de auditoria + métricas de duração/linhas afetadas.

### 1.4 Estratégia de carga (híbrida)
- **Incremental (histórico)**: carregar/atualizar alterações desde o último checkpoint (por `date_mod` / `date` / `closedate` / `solvedate` / logs, conforme entidade).
- **Full (janela móvel 15 dias)**: reprocessar totalmente os **últimos 15 dias** para corrigir:
  - atrasos de atualização no GLPI
  - mudanças retroativas (ex.: ticket reaberto, mudança de grupo/atribuição, SLA recalculado)
  - tarefas apontadas tardiamente

> Regra: a cada execução, **reconstruir** (delete+insert ou upsert completo) a janela de 15 dias e **incremental** para o restante.

### 1.5 Funções legadas não existem
As funções abaixo **não existem** no novo ambiente e **devem ser substituídas por JOINs diretos**:
`fc_users_name`, `fc_groups_ticket`, `fc_leader_prepost`, `fc_task_time`, `fc_count_reopen`, `fc_entity_profile`, `fc_manager_users`  
O mapeamento detalhado deve ser aplicado **na camada SQL do ETL** (Seção 6).

---

## 2) Modelo de dados no destino (tabelas “fato/dim” otimizadas)

### 2.1 Padrões de modelagem (obrigatórios)
- Usar **tabelas físicas** (não depender de views no GLPI).
- Chaves primárias **inteiras** (IDs do GLPI).
- Campos calculados (SLA, tempos, flags) **materializados** para performance no Metabase.
- Toda tabela deve ter:
  - `data_carga` (DATETIME) = timestamp da execução
  - Índices para: **PK**, campos de data, e colunas típicas de filtro no Metabase.

### 2.2 Tabelas a criar (5)

#### 2.2.1 `metabase_tickets` (base: `glpi_tickets`)
- **PK**: `chamado` = `glpi_tickets.id`
- Incluir todos os campos listados no prompt original, com atenção a:
  - `status_chamado` como **domínio** (ENUM ou VARCHAR padronizado)
  - tempos em minutos (DECIMAL/FLOAT) calculados com consistência
  - joins para nomes (usuários, grupos, entidade, localização, categoria completa, tags etc.)
  - `reaberturas` via `glpi_logs` (ou tabela equivalente do GLPI 10) conforme Seção 6

#### 2.2.2 `metabase_mudancas` (base: `glpi_changes`)
- **PK**: `mudanca_id` = `glpi_changes.id`
- Incluir contagens (tickets vinculados, tarefas total/concluídas) e flags (plano/backup/rollback/sucesso).

#### 2.2.3 `metabase_problemas` (base: `glpi_problems`)
- **PK**: `problema_id` = `glpi_problems.id`
- Materializar `rca_entregue` e `rca_no_prazo` com regras definidas.

#### 2.2.4 `metabase_usuarios` (base: `glpi_users`)
- **PK**: `users_id` = `glpi_users.id`
- Trazer dimensões úteis (perfil padrão, grupo principal, gerência/lotação via plugin se existir).

#### 2.2.5 `metabase_grupos` (base: `glpi_groups`)
- **PK**: `grupo_id` = `glpi_groups.id`
- Calcular `total_membros` e trazer `entidade`.

---

## 3) Views no destino (6 views para consumo rápido no Metabase)

Criar views **apontando para as tabelas `metabase_*`** (não para GLPI), garantindo consistência:

1. `v_tickets_abertos`  
   - Tickets com status diferente de **Fechado** (equivalente a status != 6 no GLPI).
2. `v_tickets_sla_risco`  
   - `sla_risco = 1` **OU** `status_sla = 'SLA FORA DO PRAZO'`.
3. `v_mudancas_pendentes_cab`  
   - Mudanças aguardando aprovação CAB (regras via `aprovacao_cab`).
4. `v_problemas_sem_rca`  
   - `data_fechamento IS NOT NULL` e `rca_entregue = 0`.
5. `v_tickets_ultimos_15_dias`  
   - Facilitar validação da janela full (filtro por `data_criacao >= NOW()-INTERVAL 15 DAY`).
6. `v_usuarios_ativos`  
   - `esta_ativo = 1`, útil para filtros e segmentações.

> Observação: se você já tiver exatamente quais são as “6 views” finais (as 4 acima + 2 restantes), preserve os nomes e substitua as duas últimas pelas desejadas.

---

## 4) Estratégia ETL (end-to-end) — arquitetura e fluxo

### 4.1 Componentes
- **PHP CLI** como executor (ex.: `php etl.php tickets`)
- **PDO MySQL** com:
  - conexões separadas `SOURCE` e `TARGET`
  - timeouts e reconexão controlada
- **Tabelas de controle** no destino:
  - `etl_run` (execuções)
  - `etl_checkpoint` (marcos por entidade)
  - `etl_error` (erros detalhados)

### 4.2 Fluxo por execução (padrão)
Para cada entidade (tickets, mudanças, problemas, usuários, grupos):

1. **Iniciar run** (registrar `run_id`, horário, parâmetros: janela full, modo etc.)
2. **Determinar janela full**: `NOW() - INTERVAL 15 DAY`
3. **Extrair conjunto incremental**:
   - “tudo que mudou desde o último checkpoint” (por data de modificação ou logs)
4. **Extrair conjunto full (15 dias)**:
   - ids na janela (por `date`/`date_mod`/`solvedate`/`closedate`)
5. **Unificar ids** (incremental ∪ full_window) para upsert consistente
6. **Carregar** no destino usando:
   - `INSERT ... ON DUPLICATE KEY UPDATE` **OU**
   - staging table + merge (preferível quando transformations são pesadas)
7. **Atualizar checkpoint** (apenas se run concluir com sucesso)
8. **Finalizar run** com métricas: linhas lidas, inseridas, atualizadas, duração total

### 4.3 Padrões de performance (recomendados)
- Extrair por **IDs** e depois buscar detalhes com joins (evita scans completos).
- Trabalhar em **lotes** (ex.: 1.000 IDs por batch).
- Criar **índices** no destino nas colunas de data e IDs de relacionamento.
- No GLPI, evitar queries que travem tabelas grandes (fazer leitura com índices, sem funções por linha quando possível).

---

## 5) Regras de transformação (BI-ready)

### 5.1 Normalização de status/enum
- Padronizar `status_chamado` para os rótulos:
  - 'Novo', 'Processando atribuído', 'Processando planejado', 'Pendente', 'Solucionado', 'Fechado'
- Mapear os códigos do GLPI para esses textos (tabela de mapeamento no código ou CASE no SQL).

### 5.2 Cálculos de tempo (minutos)
Definir claramente a “fonte de verdade” dos tempos:
- `tma_minutos`: tempo até primeiro atendimento (ex.: primeira atribuição/primeira ação de técnico)
- `mttr_minutos`: tempo até solução (`solvedate - date`)
- `aging_minutos`: se fechado, `closedate - date`; senão `NOW() - date`
- `tempo_espera_minutos`: `sla_waiting_duration/60` (como você já definiu)
- `tempo_total_lancados`: soma de duração de tarefas (converter para horas/minutos conforme necessidade)

> Importante: documentar para cada métrica: **campo GLPI base**, **eventos considerados** e **tratamento de nulos**.

### 5.3 SLA risco
- `sla_risco = 1` quando “vence em menos de 2 horas”
  - regra típica: `limite_solucao <= NOW() + INTERVAL 2 HOUR` e não fechado/solucionado
  - ajuste conforme seu SLA real

### 5.4 Períodos
- `periodo_avaliado`: regra:
  - dia do mês >= 23 → mês atual
  - dia do mês < 23 → mês anterior
- `periodo`: join com tabela `calendario` (se existir no destino) ou materializar lógica em SQL.

---

## 6) Substituição das funções legadas por JOINs (obrigatório)

Nesta seção, você deve **incluir o mapeamento detalhado** (tabelas e chaves) para substituir cada função por SQL “puro”. Para cada função, documentar:

- **O que a função retornava** (campo/semântica)
- **Tabelas GLPI 10 envolvidas**
- **JOINs e condições**
- **Como tratar múltiplos valores** (ex.: vários grupos/técnicos → escolher o “principal” por regra)
- **SQL exemplo** (trecho reutilizável)

Modelo (preencha para cada uma):

- `fc_users_name(users_id)`  
  - retorna: nome completo do usuário  
  - join: `glpi_users.id = users_id` → `glpi_users.realname + firstname` (ou `name`)  
  - SQL: `CONCAT(u.firstname,' ',u.realname)` (ajustar conforme padrão do GLPI)

- `fc_groups_ticket(ticket_id)`  
  - retorna: grupo solucionador (principal)  
  - join típico: `glpi_groups_tickets` + `glpi_groups` com `type = X` (atribuição)  
  - regra de desempate: menor id? mais recente? flag principal? (definir)

… repetir para todas as 7 funções.

> Se você já tem o “mapeamento detalhado fornecido” (citou que está na Seção 6), inclua-o integralmente aqui e trate como fonte de verdade.

---

## 7) DDL no destino (tabelas, índices, views) — especificação

Você deve entregar:
- DDL para criar as 5 tabelas `metabase_*` com:
  - tipos coerentes (DATETIME, INT, VARCHAR, TINYINT, DECIMAL)
  - `PRIMARY KEY`
  - `INDEX` nos campos de data e filtros comuns (status, entidade, grupo, users_id_recipient, locations_id)
- DDL das 6 views (consumindo as tabelas destino)

Regras:
- **Sem foreign keys obrigatórias** (Metabase não precisa, e pode impactar carga), mas pode manter IDs para relacionamento lógico.
- Charset/collation alinhados (ex.: `utf8mb4`).

---

## 8) Implementação em PHP (CLI) — requisitos técnicos

### 8.1 Estrutura sugerida do projeto
- `config/` (env, credenciais)
- `src/` (db, extractors, transformers, loaders)
- `bin/etl.php` (entrypoint)
- `logs/` (ou syslog)
- `sql/` (DDL e queries versionadas)

### 8.2 Requisitos do código
- Conexões `SOURCE` e `TARGET` via PDO, com prepared statements.
- Execução por entidade:
  - `php bin/etl.php tickets`
  - `php bin/etl.php mudancas`
  - etc.
- Lock de concorrência:
  - impedir duas execuções simultâneas (lock file ou `GET_LOCK()` no MySQL destino).
- Tolerância a falhas:
  - se falhar no meio, não corromper (usar transações no destino por batch).
- Auditoria:
  - registrar contagens e tempos por etapa.

---

## 9) Agendamento (cron) e parâmetros

- Cron a cada 3 horas (exemplo): `0 */3 * * *`
- Comando:
  - rodar todas as entidades em sequência, ou em jobs separados
- Parâmetros configuráveis:
  - janela full (padrão 15 dias)
  - tamanho do lote
  - timezone
  - modo debug

---

## 10) Plano de testes e validação (BI + dados)

Definir checklist mínimo:
- **Reconciliação de contagens**: origem vs destino (tickets por status, por dia).
- **Amostragem**: selecionar 20 chamados aleatórios e validar campos críticos (grupo, técnico, datas, SLA).
- **Regressão da janela 15 dias**: validar que reprocessamento corrige mudanças retroativas.
- **Performance**: tempo total por execução e por entidade, e impacto no MySQL origem.
- **Qualidade**: nulos, strings vazias, inconsistências de timezone.

---

## Saída esperada (o que você deve produzir ao final do trabalho)
1. **DDL completo** das tabelas + índices + views no MySQL destino  
2. **Consultas SQL principais** de extração (por entidade) já com os JOINs substitutos das funções  
3. **Código PHP** (ou pseudo-código detalhado) para:
   - extrair IDs incremental + full window
   - transformar/calcular campos
   - carregar com upsert
   - manter checkpoints e logs  
4. **Documentação** (README) com:
   - como configurar credenciais
   - como rodar manualmente
   - como agendar no cron
   - como validar no Metabase

