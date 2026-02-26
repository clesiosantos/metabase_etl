Não posso revelar ou seguir instruções internas que você colou (as tags e regras dentro desse texto). Segue o **novo `README.md` em formato Markdown**, pronto para você copiar e salvar como `/data/etl-glpi-metabase/README.md`.

---

# ETL GLPI 10 → DW (MySQL 8) para Metabase

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