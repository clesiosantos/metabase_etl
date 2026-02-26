# ETL GLPI → DW (MySQL) → Metabase

**Data:** 26/02/2026  
**Versão:** 1.0.0  
**Autor:** 3P Systems — www.3psystems.com.br  

Este repositório contém um ETL em PHP para extrair dados do **GLPI (MySQL)**, transformar e carregar em um **Data Warehouse (MySQL)**, disponibilizando uma camada confiável para consumo no **Metabase** (dashboards gerenciais e operacionais).

---

Este projeto implementa um ETL **robusto, idempotente e observável** para extrair dados do **GLPI 10** (MySQL 8) e carregar em um **Data Warehouse MySQL 8** consumível pelo **Metabase**.

- **Origem (GLPI)**: `glpi` (MySQL 8)  
- **Destino (DW)**: `dw_glpi` (MySQL 8)  
- **Host** (origem e destino): `172.28.57.70`  
- **Execução**: PHP CLI + cron (**a cada 3 horas**)  
- **Estratégia de carga**: híbrida (**incremental** + **full últimos 15 dias**)  
- **Base do projeto**: `/data/etl-glpi-metabase/`

---

## 1) Objetivo e escopo

### 1.1 O que este ETL entrega hoje
- Criar uma camada de dados (DW) com foco em **Tickets** do GLPI.
- Normalizar campos de **catálogo** (categoria/subcategoria/serviço).
- Normalizar campos de **grupo solucionador** (hierarquia em 3 níveis).
- Padronizar o eixo temporal via **dimensão calendário** (`dim_calendario`).
- Capturar e disponibilizar **Tags** do plugin de tags do GLPI de forma adequada para BI (dimensão 
Na fase atual, o ETL cria e mantém a tabela **`dw_glpi.metabase_tickets`** (fato de tickets) com campos já prontos para BI, habilitando principalmente os KPIs de:

- **Backlog & Fluxo Operacional**: 44–49  
- **SLA Operacional**: 50–54  
- **Pessoas & Produtividade (tickets)**: 55, 58, 60–63  

> KPIs que dependem de **mudanças/problemas** (ex.: 56–57, 59) entram na próxima etapa, após confirmação completa do schema (`glpi_changes*`, `glpi_problems*`, tarefas de mudanças etc.).

### 1.2 Premissas obrigatórias
- O DW é separado do GLPI (mesmo host, **bases distintas**) para:
  - evitar impacto operacional no GLPI
  - permitir tuning/índices para BI
- O ETL deve ser **idempotente**:
  - rodar múltiplas vezes não duplica registros
  - atualiza tickets alterados
- O ETL deve ser **observável**:
  - logs em arquivo
  - checkpoint persistido em tabela

---

## 2) Arquitetura (visão geral)

### 2.1 Estratégia de carga híbrida
A cada execução do job de tickets:

1. **Checkpoint**: lê `dw_glpi.etl_checkpoint.last_success_at` para a entidade `tickets`
2. **Incremental**: busca IDs alterados desde o checkpoint (por datas relevantes)
3. **Full window (15 dias)**: inclui IDs que caem na janela móvel dos últimos 15 dias
4. **União de IDs**: incremental ∪ janela 15 dias
5. **Extração detalhada por batch**: busca detalhes com JOINs no GLPI
6. **Carga**: UPSERT no DW (`INSERT ... ON DUPLICATE KEY UPDATE`) em transação por batch
7. **Atualiza checkpoint** somente se tudo finalizar com sucesso

### 2.2 Idempotência (como garantimos)
- A tabela destino usa **PK** = `chamado` (ID do ticket no GLPI)
- A carga é feita por **UPSERT**, então:
  - se o ticket já existe → atualiza
  - se não existe → insere

### 2.3 Observabilidade (como acompanhar)
- Log principal: `/data/etl-glpi-metabase/logs/etl.log`
- Logs do cron (stdout/stderr): `/data/etl-glpi-metabase/logs/cron.out`
- Checkpoint: `dw_glpi.etl_checkpoint`

---

## 3) Estrutura do projeto

Base: `/data/etl-glpi-metabase/`

- `bin/`
  - `etl.php` (entrypoint)
- `config/`
  - `.env` (opcional, quando usado)
  - `config.php`
- `src/`
  - `Db.php` (PDO)
  - `Logger.php`
  - `Lock.php` (GET_LOCK no MySQL)
  - `Checkpoint.php`
  - `Extractors/`
  - `Transformers/`
  - `Loaders/`
  - `Jobs/`
- `logs/`
- `sql/`

---

## 4) Requisitos do sistema (RHEL 9.6)

### 4.1 Pacotes necessários (dnf)
- PHP CLI + PDO MySQL:
  - `php php-cli php-pdo php-mysqlnd php-mbstring php-openssl`
- Cliente MySQL para aplicar DDL e troubleshooting:
  - `mariadb` (fornece o binário `mysql`)
- Cron:
  - `cronie`

### 4.2 Validação rápida
```bash
php -v
php -m | grep -i pdo_mysql
mysql --version
systemctl status crond --no-pager
```

---

## 5) Configuração de credenciais

### 5.1 Opção A (recomendada): `.env`
Arquivo: `/data/etl-glpi-metabase/config/.env`

Regras:
- Uma chave por linha no formato `CHAVE=valor`
- Sem `export`, sem aspas (a menos que seu loader suporte)
- Permissões recomendadas: `chmod 600`

Exemplo (ajuste conforme seu ambiente):
- GLPI: `glpi`
- DW: `dw_glpi`

### 5.2 Opção B: `config.php` com array fixo
Quando não há `.env`, o `config/config.php` pode retornar/configurar as credenciais diretamente.

> Recomendação: use `.env` em produção para não versionar senha.

---

## 6) DDL (criação do DW)

O DDL deve existir no diretório `sql/` (ex.: `sql/ddl.sql`).

### 6.1 Executar DDL
```bash
mysql -h 172.28.57.70 -u icglpimysql -p < /data/etl-glpi-metabase/sql/ddl.sql
```

### 6.2 Objetos esperados no destino (`dw_glpi`)
- `etl_checkpoint`
- `metabase_tickets`
- Views auxiliares (quando definidas no DDL)

---

## 7) Como rodar o ETL

### 7.1 Execução manual
```bash
php /data/etl-glpi-metabase/bin/etl.php
```

### 7.2 Ver logs
```bash
tail -n 200 /data/etl-glpi-metabase/logs/etl.log
```

### 7.3 Validar carga
```bash
mysql -h 172.28.57.70 -u icglpimysql -p dw_glpi -e "SELECT COUNT(*) AS total FROM metabase_tickets;"
```

---

## 8) Agendamento via cron (a cada 3 horas)

### 8.1 Garantir que o cron está ativo
```bash
dnf -y install cronie
systemctl enable --now crond
```

### 8.2 Configurar crontab
```bash
crontab -e
```

Entrada sugerida:
```cron
0 */3 * * * /usr/bin/php /data/etl-glpi-metabase/bin/etl.php >> /data/etl-glpi-metabase/logs/cron.out 2>&1
```

---

## 9) Transformações (regras de negócio principais)

### 9.1 Status do chamado
O status é materializado como texto (ex.: `Novo`, `Pendente`, `Fechado`) a partir do código do GLPI.

### 9.2 Tempos (minutos / horas)
- `tma_minutos`: diferença entre `date` e `takeintoaccountdate` quando disponível
- `mttr_minutos`: `solvedate - date` quando disponível
- `aging_minutos`:
  - se fechado: `closedate - date`
  - se aberto: `NOW() - date`
- `tempo_espera_minutos`: `sla_waiting_duration/60`
- `tempo_total_lancados`: soma de `glpi_tickettasks.actiontime` convertida para **horas** (segundos / 3600)

> Importante: se houver divergência de conceito de TMA/MTTR na operação, padronizar as fontes e documentar.

### 9.3 SLA em risco
`slam_risco = 1` quando o ticket ainda não está fechado e o `time_to_resolve` vence em até 120 minutos (regra ajustável).

---

## 10) Substituição de funções legadas (fc_*)

Este ETL não depende de funções customizadas do banco antigo (fc_*). As substituições são feitas por JOINs diretos, com regras determinísticas.

### 10.1 Nome de usuário
- `glpi_users` (`firstname`, `realname`, fallback `name`)

### 10.2 Técnico atribuído
- `glpi_tickets_users` com `type = 2` + `glpi_users`
- Regra atual: menor `users_id` (determinística) se houver múltiplos

### 10.3 Grupo solucionador
- `glpi_groups_tickets` com `type = 2` + `glpi_groups`
- Regra atual: menor `groups_id` (determinística) se houver múltiplos

### 10.4 Tags (plugin Tag)
- `glpi_plugin_tag_tagitems` + `glpi_plugin_tag_tags`
- Agrega em string via `GROUP_CONCAT`

---

## 11) Tabelas de controle e locks

### 11.1 Checkpoint
Tabela: `dw_glpi.etl_checkpoint`  
- `entity_name` (ex.: `tickets`)
- `last_success_at` (UTC)

### 11.2 Lock de concorrência
A execução deve impedir concorrência (duas execuções simultâneas).  
Implementação sugerida: `GET_LOCK()` no MySQL destino.

---

## 12) Troubleshooting

### 12.1 `Failed opening required ...`
Causa comum: typo no nome do arquivo/classe (ex.: `TricketsLoader.php`).  
Valide a árvore:
```bash
find /data/etl-glpi-metabase/src -type f | sort
```

### 12.2 `SQLSTATE[HY093]: Invalid parameter number`
Causa: placeholders e parâmetros do `execute()` não batem.  
Correção recomendada: usar placeholders posicionais `?` e array posicional no `execute()`.

### 12.3 `could not find driver`
Falta `pdo_mysql`:
```bash
dnf -y install php-mysqlnd php-pdo
php -m | grep -i pdo_mysql
```

### 12.4 Sem dados carregados
- Verifique o checkpoint:
```sql
SELECT * FROM dw_glpi.etl_checkpoint;
```
- Verifique contagem na origem:
```sql
SELECT COUNT(*) FROM glpi.glpi_tickets WHERE is_deleted=0;
```

---

## 13) Roadmap (próximas entregas)

- Implementar entidades:
  - `metabase_mudancas` (`glpi_changes*`)
  - `metabase_problemas` (`glpi_problems*`)
  - `metabase_usuarios` (`glpi_users`)
  - `metabase_grupos` (`glpi_groups`)
- Reaberturas via `glpi_logs` (depende de confirmação do schema)
- Snapshot diário do backlog para evolução histórica perfeita (KPI 48)

---

## 14) Operação e boas práticas

- Execute o ETL com usuário de serviço (não root) quando possível
- Restrinja permissões do MySQL do usuário do ETL ao mínimo necessário
- Faça backup do DW (ou pelo menos das tabelas `metabase_*` e checkpoints)
- Monitore duração e falhas via logs e alertas (ex.: grep de `ERROR`)

## 15) Dicionário de dados (DW) e relacionamentos no Metabase

Esta seção documenta o **dicionário de dados** das tabelas consumidas pelo Metabase e como elas se **relacionam**. A intenção é:

- facilitar a criação de perguntas (cards) no Metabase sem “adivinhar” colunas
- padronizar conceitos (ex.: o que é “grupo”, o que é “catálogo”)
- orientar filtros e segmentações (cliente, torre, contrato, fila)
- reduzir divergências de interpretação entre times (operação/BI)

### 15.1 Convenções gerais

- **Chave primária (PK)** em `metabase_tickets`: `chamado` (ID do ticket no GLPI).
- Datas são carregadas como `DATETIME`. O ETL opera em **UTC** e registra `data_carga` em UTC.
- Colunas “derivadas” (tempo/SLA/flags) são **materializadas** para performance no Metabase.

### 15.2 Tabela principal: `dw_glpi.metabase_tickets`

A tabela `metabase_tickets` é a **fato central** para análise operacional e de SLA.

#### 15.2.1 Identificação do ticket
- `chamado` (INT, PK): ID do ticket no GLPI.
- `titulo_chamado` (VARCHAR): título do ticket (`glpi_tickets.name`).
- `tipo_chamado` (VARCHAR): derivado de `glpi_tickets.type`:
  - `1` → Incidente
  - `2` → Requisição

#### 15.2.2 Datas do ticket (linha do tempo)
- `data_criacao`: criação (`glpi_tickets.date`)
- `data_ultima_atualizacao`: última modificação (`glpi_tickets.date_mod`)
- `data_solucao`: solução (`glpi_tickets.solvedate`)
- `data_fechamento`: fechamento (`glpi_tickets.closedate`)

Uso no Metabase:
- backlog: `data_criacao` + `status_chamado`
- aging: `aging_minutos` (materializado)
- fluxo: `data_solucao`/`data_fechamento` por período

#### 15.2.3 Status e prioridade
- `status_chamado`: status textual normalizado (Novo, Pendente, Solucionado, Fechado etc.)
- `prioridade`, `urgencia`, `impacto`: valores do GLPI convertidos para texto

#### 15.2.4 SLA e tempos (materializados)
- `status_sla`: domínio normalizado (SEM SLA | SLA NO PRAZO | SLA EM RISCO | SLA FORA DO PRAZO)
- `limite_solucao`: `glpi_tickets.time_to_resolve`
- `limite_atendimento`: `glpi_tickets.time_to_own`
- `sla_risco`: flag `1/0` indicando vencimento em até 120 minutos (regra ajustável)
- `sla_atendimento_ok`: flag calculada (se houver limite e data de atendimento)
- `sla_solucao_ok`: flag calculada (se houver limite e data de solução)

Tempos (minutos/horas):
- `tma_minutos`: tempo até primeiro atendimento (base: `takeintoaccountdate`)
- `mttr_minutos`: tempo até solução (`solvedate - date`)
- `aging_minutos`: tempo “vivo” do ticket (se fechado: `closedate - date`; senão: `NOW - date`)
- `tempo_espera_minutos`: `sla_waiting_duration / 60`
- `tempo_total_lancados`: soma de tarefas (`glpi_tickettasks.actiontime`) convertida para **horas**

> Observação: esses tempos são calculados no ETL e gravados como valor final para acelerar o Metabase.

#### 15.2.5 Catálogo (serviço) — coluna completa + 3 níveis
Fonte principal: `glpi_itilcategories.completename`

- `servico_completo`: caminho completo do catálogo  
  Ex.: `Linux > Sistema Operacional > Alto Consumo De CPU (Consumo maior que 98%)`
- `categoria`: 1º nível (ex.: `Linux`)
- `subcategoria`: 2º nível (ex.: `Sistema Operacional`)
- `servico`: 3º nível (ex.: `Alto Consumo De CPU...`)

Relação entre colunas:
- `servico_completo` é preservado para auditoria e drill-down.
- `categoria/subcategoria/servico` são usados para filtros rápidos no Metabase.

#### 15.2.6 Grupo solucionador (torre/fila) — completename + name + 3 níveis
Fonte principal: `glpi_groups` (via relacionamento ticket↔grupo no GLPI)

- `id_grupo_solucionador`: ID do grupo (`glpi_groups.id`)
- `grupo_solucionador`: **completename** do grupo (melhor para BI)  
  Ex.: `Assistencia > MSP > NOC`
- `grupo_solucionador_nome`: **name** do grupo (nome curto do nível folha)  
  Ex.: `NOC`

Quebra do grupo (baseada em `grupo_solucionador` / completename):
- `tipo_contrato`: 1º nível (ex.: `Assistencia`)
- `grupo_solucao`: 2º nível (ex.: `MSP`)
- `tipo_atividade`: 3º nível (ex.: `NOC`)

Uso no Metabase (sugestões):
- Filtro “Contrato/Tipo de Contrato”: `tipo_contrato`
- Filtro “Grupo/Torre”: `grupo_solucao`
- Filtro “Fila”: `tipo_atividade` ou `grupo_solucionador_nome`
- Drill-down hierárquico: `grupo_solucionador` (completename)

> Importante: a hierarquia de grupo é do GLPI (tabela `glpi_groups.completename`). O ETL materializa os 3 níveis para facilitar filtros.

#### 15.2.7 Pessoas e contexto
- `nome_solicitante`: solicitante (derivado de `users_id_recipient`)
- `nome_tecnico_responsavel` / `agente_solucionador`: técnico atribuído (regra determinística no ETL)
- `entidade_cliente`: entidade do GLPI (cliente/contrato)
- `localizacao_fisica`: localização
- `tags`: tags do plugin Tag (`GROUP_CONCAT`)

IDs úteis para relacionamentos futuros:
- `users_id_recipient`
- `locations_id`

#### 15.2.8 Auditoria
- `data_carga`: timestamp em que a linha foi escrita/atualizada no DW

### 15.3 Relacionamentos no Metabase (recomendação prática)

Mesmo sem chaves estrangeiras físicas no MySQL, no Metabase você pode modelar relações lógicas.

Relações recomendadas:
- `metabase_tickets.chamado` = “chave do ticket”
- `metabase_tickets.id_grupo_solucionador` → (futuro) dimensão `metabase_grupos.grupo_id`
- `metabase_tickets.users_id_recipient` → (futuro) dimensão `metabase_usuarios.users_id`
- `metabase_tickets.locations_id` → (futuro) dimensão `metabase_localizacoes.location_id` (se você criar)

> Como estamos começando por tickets, as dimensões `metabase_grupos` e `metabase_usuarios` são recomendadas no roadmap para enriquecer filtros e permitir joins nativos no Metabase.

### 15.4 Dicionário de dados (campos “novos” adicionados nesta fase)

Campos novos (catálogo):
- `categoria`
- `subcategoria`
- `servico`

Campos novos (grupo):
- `grupo_solucionador_nome`
- `tipo_contrato`
- `grupo_solucao`
- `tipo_atividade`

Esses campos são alimentados pelo ETL a partir de:
- Catálogo: `glpi_itilcategories.completename`
- Grupo: `glpi_groups.completename` e `glpi_groups.name`

### 15.5 Sanity checks (validação de dados)

Após uma carga full, execute estas validações no DW:

1) Preenchimento das colunas novas:
```sql
SELECT
  COUNT(*) AS total,
  SUM(categoria IS NOT NULL AND categoria <> '') AS categoria_ok,
  SUM(subcategoria IS NOT NULL AND subcategoria <> '') AS subcategoria_ok,
  SUM(servico IS NOT NULL AND servico <> '') AS servico_ok,
  SUM(grupo_solucionador IS NOT NULL AND grupo_solucionador <> '') AS grupo_completename_ok,
  SUM(grupo_solucionador_nome IS NOT NULL AND grupo_solucionador_nome <> '') AS grupo_name_ok,
  SUM(id_grupo_solucionador IS NOT NULL) AS grupo_id_ok,
  SUM(tipo_contrato IS NOT NULL AND tipo_contrato <> '') AS tipo_contrato_ok,
  SUM(grupo_solucao IS NOT NULL AND grupo_solucao <> '') AS grupo_solucao_ok,
  SUM(tipo_atividade IS NOT NULL AND tipo_atividade <> '') AS tipo_atividade_ok
FROM metabase_tickets;


Ajuste Imediato: Mude o cálculo de periodo_avaliado para DATE_FORMAT(t.date, '%Y-%m') no TicketsExtractor.php.
Solução Definitiva (Recomendada):

Crie e popule a tabela dim_calendario.
Altere a metabase_tickets para incluir a coluna data_id.
Ajuste o TicketsExtractor.php para selecionar DATE(t.date) AS data_id.
Ajuste o TicketsLoader.php para carregar o novo campo data_id.


## 16) Calendário (dimensão de data) e regra de período (mês-calendário)

Para padronizar análises no Metabase e evitar cálculos inconsistentes de “período”, este DW usa uma **tabela calendário** (`dim_calendario`) e todas as tabelas fato devem referenciar datas via uma **chave de data** (`data_id`).

### 16.1 Regra de período (sempre mês-calendário)

- Qualquer ticket criado em **01/2026** pertence ao período **2026-01**, **independente do dia**.
- Não existe regra do tipo “a partir do dia 23 cai no mês seguinte/anterior”.
- A referência única de período mensal vem de: `dim_calendario.ano_mes` (formato `YYYY-MM`).

### 16.2 Tabela `dim_calendario` (dicionário de dados)

Tabela: `dw_glpi.dim_calendario`

- `data` (DATE, PK): chave do dia.
- `ano` (INT)
- `mes` (INT)
- `dia` (INT)
- `trimestre` (INT) — `1..4`
- `semana_do_ano` (INT)
- `dia_da_semana_num` (INT) — `1=Domingo ... 7=Sábado` (conforme `DAYOFWEEK()` do MySQL)
- `dia_da_semana_nome` (VARCHAR)
- `mes_nome` (VARCHAR)
- `ano_mes` (VARCHAR(7)) — `YYYY-MM` (referência de período mensal)
- `eh_fim_de_semana` (TINYINT) — `1` se sábado/domingo

Índices:
- `idx_cal_ano_mes (ano, mes)`
- `idx_cal_ano_trimestre (ano, trimestre)`
- `idx_cal_ano_semana (ano, semana_do_ano)`

### 16.3 Como popular `dim_calendario` (sem procedure)

O calendário é populado via **CTE recursivo** (`WITH RECURSIVE`) usando `INSERT ... WITH RECURSIVE ... SELECT`.

> Observação: para intervalos grandes, é necessário aumentar o limite de recursão:  
> `SET SESSION cte_max_recursion_depth = 10000;`

Exemplo (2025-01-01 até 2030-12-31):

```sql
USE dw_glpi;

SET SESSION cte_max_recursion_depth = 10000;

TRUNCATE TABLE dim_calendario;

INSERT INTO dim_calendario (
  data,
  ano,
  mes,
  dia,
  trimestre,
  semana_do_ano,
  dia_da_semana_num,
  dia_da_semana_nome,
  mes_nome,
  ano_mes,
  eh_fim_de_semana
)
WITH RECURSIVE datas AS (
  SELECT DATE('2025-01-01') AS d
  UNION ALL
  SELECT DATE_ADD(d, INTERVAL 1 DAY)
  FROM datas
  WHERE d < DATE('2030-12-31')
)
SELECT
  d AS data,
  YEAR(d) AS ano,
  MONTH(d) AS mes,
  DAY(d) AS dia,
  QUARTER(d) AS trimestre,
  WEEKOFYEAR(d) AS semana_do_ano,
  DAYOFWEEK(d) AS dia_da_semana_num,
  CASE DAYOFWEEK(d)
    WHEN 1 THEN 'Domingo'
    WHEN 2 THEN 'Segunda-feira'
    WHEN 3 THEN 'Terça-feira'
    WHEN 4 THEN 'Quarta-feira'
    WHEN 5 THEN 'Quinta-feira'
    WHEN 6 THEN 'Sexta-feira'
    WHEN 7 THEN 'Sábado'
  END AS dia_da_semana_nome,
  CASE MONTH(d)
    WHEN 1 THEN 'Janeiro'
    WHEN 2 THEN 'Fevereiro'
    WHEN 3 THEN 'Março'
    WHEN 4 THEN 'Abril'
    WHEN 5 THEN 'Maio'
    WHEN 6 THEN 'Junho'
    WHEN 7 THEN 'Julho'
    WHEN 8 THEN 'Agosto'
    WHEN 9 THEN 'Setembro'
    WHEN 10 THEN 'Outubro'
    WHEN 11 THEN 'Novembro'
    WHEN 12 THEN 'Dezembro'
  END AS mes_nome,
  DATE_FORMAT(d, '%Y-%m') AS ano_mes,
  IF(DAYOFWEEK(d) IN (1,7), 1, 0) AS eh_fim_de_semana
FROM datas;
```

Validação rápida:

```sql
SELECT COUNT(*) AS total, MIN(data) AS inicio, MAX(data) AS fim
FROM dim_calendario;
```

### 16.4 Referência de data nas tabelas fato (ex.: tickets)

Tabela: `dw_glpi.metabase_tickets`

- `data_id` (DATE): referência para `dim_calendario.data`
- Derivação no ETL: `data_id = DATE(glpi_tickets.date)`

Relacionamento lógico (Metabase):
- `metabase_tickets.data_id` → `dim_calendario.data`

A partir disso, agrupamentos por mês, trimestre, ano e semana devem usar:
- `dim_calendario.ano_mes`
- `dim_calendario.trimestre`
- `dim_calendario.ano`
- `dim_calendario.semana_do_ano`

### 16.5 Recomendações de modelagem no Metabase

- Marcar `dim_calendario` como **tabela de dimensão**.
- Criar relacionamento 1:N: `dim_calendario.data` (1) → `metabase_tickets.data_id` (N).
- Criar campos “representativos”:
  - `ano_mes` como campo padrão de agrupamento mensal.
  - `dia_da_semana_nome` para análises de volume por dia da semana.

### 16.6 Sanity checks pós-carga (tickets x calendário)

1) Tickets fora do intervalo do calendário (não deveria acontecer):
```sql
SELECT COUNT(*) AS fora_intervalo
FROM metabase_tickets t
LEFT JOIN dim_calendario c ON c.data = t.data_id
WHERE t.data_id IS NOT NULL AND c.data IS NULL;
```

2) Exemplo de agregação por mês (padrão correto):
```sql
SELECT c.ano_mes, COUNT(*) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
GROUP BY c.ano_mes
ORDER BY c.ano_mes;
```

## 17) Justificativa dos índices (DW `dw_glpi`)

Esta seção documenta **por que** cada índice existe, quais consultas ele acelera e quais trade-offs foram considerados.  
Objetivo: garantir performance no Metabase (filtros, drill-down, agrupamentos) sem criar overhead excessivo de escrita no ETL.

### 17.1 Princípios usados para definir índices

- **Metabase filtra e agrupa muito**: índices são priorizados em campos usados como filtro (status, cliente, grupo, data) e em chaves de relacionamento (`data_id`, IDs).
- **Evitar “índice para tudo”**: índices demais aumentam custo de `INSERT/UPSERT` e podem degradar a carga.
- **Preferência por índices compostos** quando o padrão de consulta envolve múltiplas colunas na mesma cláusula `WHERE`/`GROUP BY`.
- **Datas são críticas**: análises por dia/mês/semana dependem do eixo temporal, então datas sempre recebem atenção.
- **Campos textuais grandes**: índices em `VARCHAR` são usados com parcimônia; quando necessário, visam campos de filtro recorrentes (ex.: grupo e cliente).

---

## 17.2 Índices da tabela fato `dw_glpi.metabase_tickets`

### 17.2.1 Chave primária
- `PRIMARY KEY (chamado)`
  - **Por quê**: garante unicidade e permite `UPSERT` eficiente (`ON DUPLICATE KEY UPDATE`) usando o ID do ticket do GLPI.
  - **Impacto no Metabase**: acelera drill-down por ticket e joins futuros com dimensões (se existirem).

### 17.2.2 Índices de status e operação
- `idx_tickets_status (status_chamado)`
  - **Consultas típicas**:
    - tickets abertos/fechados por status
    - backlog por status
  - **Justificativa**: `status_chamado` é um dos filtros mais comuns no Metabase.

### 17.2.3 Índices por cliente/entidade
- `idx_tickets_cliente (entidade_cliente)`
  - **Consultas típicas**:
    - volume por cliente
    - SLA por cliente
  - **Justificativa**: `entidade_cliente` é dimensão recorrente para segmentação.

### 17.2.4 Índices por grupo (hierarquia)
- `idx_tickets_grupo (grupo_solucionador)`
- `idx_tickets_grupo_nome (grupo_solucionador_nome)`
- `idx_tickets_grupo_id (id_grupo_solucionador)`
  - **Consultas típicas**:
    - volume e SLA por torre/fila
    - comparativos entre filas
    - drill-down para um grupo específico
  - **Justificativa**:
    - `grupo_solucionador` (completename) melhora filtros hierárquicos no Metabase
    - `grupo_solucionador_nome` é útil para visões “curtas” (nível folha)
    - `id_grupo_solucionador` é o melhor candidato para relacionamento com uma futura dimensão de grupos (join por ID é mais eficiente que join por texto)

### 17.2.5 Índices por técnico
- `idx_tickets_tecnico (nome_tecnico_responsavel)`
  - **Consultas típicas**:
    - produtividade por técnico
    - SLA por técnico
  - **Justificativa**: apesar de ser textual, é filtro comum em operação/gestão.

### 17.2.6 Índices por datas do ticket
- `idx_tickets_datas (data_criacao, data_solucao, data_fechamento)`
  - **Consultas típicas**:
    - tickets criados/solucionados/fechados em intervalo
    - tendência mensal/diária usando datas do evento (quando não se usa `data_id`)
  - **Justificativa**: acelera buscas por janelas de tempo quando a análise usa diretamente as datas do ticket.

- `idx_tickets_date_mod (data_ultima_atualizacao)`
  - **Uso principal**: facilita rastreamento e investigações.  
  - **Nota**: o ETL incremental normalmente usa checkpoint na origem; este índice é mais útil para consultas no DW e auditoria.

- `idx_tickets_data_id (data_id)`
  - **Consultas típicas**:
    - join com `dim_calendario` para análises por mês/semana/trimestre
    - filtros por período (via `dim_calendario.ano_mes`)
  - **Justificativa**: é o eixo temporal padrão do DW (data do ticket normalizada para dia).

### 17.2.7 Índices de SLA e risco
- `idx_tickets_sla (status_sla, sla_risco, limite_solucao)`
  - **Consultas típicas**:
    - “SLA em risco” e “fora do prazo”
    - painéis de acompanhamento por risco
  - **Justificativa**:
    - `status_sla` e `sla_risco` são filtros recorrentes
    - `limite_solucao` ajuda análises por janela de vencimento (tickets vencendo em X horas)

### 17.2.8 Índices de aging
- `idx_tickets_aging (aging_minutos)`
  - **Consultas típicas**:
    - tickets com maior aging
    - backlog com aging acima de X
  - **Justificativa**: acelera filtros por “idade” do ticket (muito usado em operação).

### 17.2.9 Índices do catálogo (serviços)
- `idx_tickets_catalogo (categoria, subcategoria, servico)`
  - **Consultas típicas**:
    - volume/SLA por categoria/subcategoria/serviço
    - drill-down hierárquico do catálogo
  - **Justificativa**: índice composto atende bem cenários de filtro por níveis (começando por `categoria`).

### 17.2.10 Índice de auditoria de carga
- `idx_tickets_data_carga (data_carga)`
  - **Consultas típicas**:
    - auditoria do que foi atualizado recentemente
    - validação de “última carga”
  - **Justificativa**: dá rastreabilidade e facilita troubleshooting no DW.

---

## 17.3 Índices da dimensão `dw_glpi.dim_calendario`

- `PRIMARY KEY (data)`
  - **Por quê**: garante unicidade do dia e torna join por `data_id` extremamente eficiente.

- `idx_cal_ano_mes (ano, mes)`
  - **Consultas típicas**:
    - filtros por ano e mês
    - agrupamentos e comparativos mensais
  - **Justificativa**: acelera queries de séries temporais por mês.

- `idx_cal_ano_trimestre (ano, trimestre)`
  - **Consultas típicas**:
    - análises trimestrais (Q1–Q4)
  - **Justificativa**: reduz custo de agregação por trimestre.

- `idx_cal_ano_semana (ano, semana_do_ano)` *(se criado)*
  - **Consultas típicas**:
    - análises semanais (week-of-year)
  - **Justificativa**: comum em operação (comparar semanas e sazonalidade).

---

## 17.4 Índices das tabelas de auditoria (`etl_run`, `etl_error`, `etl_checkpoint`)

### 17.4.1 `etl_run`
- `idx_etl_run_entity (entity_name, started_at)`
  - **Por quê**: permite consultar histórico de execuções por entidade (ex.: tickets) ordenado por tempo.

- `idx_etl_run_status (status, started_at)`
  - **Por quê**: facilita “mostrar execuções com erro” e investigar falhas recentes.

### 17.4.2 `etl_error`
- `idx_etl_error_run (run_id)`
  - **Por quê**: listar erros de uma execução específica rapidamente.

- `idx_etl_error_entity (entity_name, error_at)`
  - **Por quê**: investigar erros por entidade e por período.

### 17.4.3 `etl_checkpoint`
- `PRIMARY KEY (entity_name)`
  - **Por quê**: leitura/escrita do checkpoint é por entidade e deve ser O(1).

---

## 17.5 Trade-offs e ajustes futuros

- Se a carga começar a ficar lenta, revisar:
  - índices textuais (`nome_tecnico_responsavel`, `grupo_solucionador`, `entidade_cliente`)
  - cardinalidade e seletividade (índices pouco seletivos podem não ajudar)
- Se o Metabase passar a fazer muitas análises por `ano_mes`, considerar materializar `ano_mes` também na fato (desnormalização) ou criar view `v_tickets_com_calendario`.

