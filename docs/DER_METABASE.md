# DER Simplificado do DW / Metabase

Este DER foi pensado para **apresentação** e entendimento rápido do modelo lógico usado pelo Metabase.

## Visão simplificada

```mermaid
erDiagram
    metabase_tickets {
        INT chamado PK
        VARCHAR tipo_chamado
        DATE data_id
        VARCHAR status_chamado
        VARCHAR entidade_cliente
        VARCHAR grupo_solucao
        VARCHAR agente_solucionador
        DATETIME data_carga
    }

    metabase_changes {
        INT chamado PK
        DATE data_id
        VARCHAR status_chamado
        VARCHAR entidade_cliente
        VARCHAR grupo_solucionador
        VARCHAR tipo_atividade
        DATETIME data_carga
    }

    metabase_problems {
        INT chamado PK
        DATE data_id
        VARCHAR status_chamado
        VARCHAR entidade_cliente
        VARCHAR grupo_solucionador
        VARCHAR causa_raiz
        DATETIME data_carga
    }

    metabase_timesheet {
        VARCHAR id_tarefa PK
        VARCHAR tipo_ticket
        INT id_pai
        VARCHAR cliente
        VARCHAR grupo_solucionador
        VARCHAR tecnico
        DATETIME data_lancamento
        DECIMAL horas
    }

    dim_tags {
        INT tag_id PK
        VARCHAR name
        TINYINT is_active
        VARCHAR color
    }

    bridge_ticket_tags {
        INT ticket_id PK
        INT tag_id PK
        DATETIME data_carga
    }

    bridge_change_tags {
        INT change_id PK
        INT tag_id PK
        DATETIME data_carga
    }

    bridge_problem_tags {
        INT problem_id PK
        INT tag_id PK
        DATETIME data_carga
    }

    etl_checkpoint {
        VARCHAR entity_name PK
        DATETIME last_success_at
    }

    etl_run {
        INT run_id PK
        VARCHAR entity_name
        VARCHAR mode
        VARCHAR status
        INT ids_selected
        INT rows_upserted
        DATETIME started_at
        DATETIME finished_at
    }

    etl_error {
        INT error_id PK
        INT run_id
        VARCHAR entity_name
        DATETIME error_at
    }

    metabase_tickets ||--o{ bridge_ticket_tags : possui
    dim_tags ||--o{ bridge_ticket_tags : classifica

    metabase_changes ||--o{ bridge_change_tags : possui
    dim_tags ||--o{ bridge_change_tags : classifica

    metabase_problems ||--o{ bridge_problem_tags : possui
    dim_tags ||--o{ bridge_problem_tags : classifica

    metabase_tickets ||--o{ metabase_timesheet : id_pai_quando_Ticket_ou_Forms
    metabase_changes ||--o{ metabase_timesheet : id_pai_quando_Change
    metabase_problems ||--o{ metabase_timesheet : id_pai_quando_Problem

    etl_run ||--o{ etl_error : registra
```

## Leitura do modelo

### Tabelas fato
- `metabase_tickets`: incidentes e requisições
- `metabase_changes`: mudanças
- `metabase_problems`: problemas
- `metabase_timesheet`: horas consolidadas

### Dimensão e pontes
- `dim_tags`: catálogo de etiquetas
- `bridge_ticket_tags`, `bridge_change_tags`, `bridge_problem_tags`: relacionamento N:N entre entidades e tags

### Tabelas operacionais do ETL
- `etl_checkpoint`: controla a última execução válida por entidade
- `etl_run`: log de execução
- `etl_error`: log de falhas

## Regras importantes para apresentação

- O modelo usa **relacionamentos lógicos**; não há `FOREIGN KEY` física no banco.
- `metabase_timesheet.id_pai` aponta para tabelas diferentes conforme `tipo_ticket`:
  - `Ticket` e `Forms` → `metabase_tickets.chamado`
  - `Change` → `metabase_changes.chamado`
  - `Problem` → `metabase_problems.chamado`
- Tags podem ser consumidas de duas formas:
  - por texto nas colunas `tags` das tabelas fato
  - por modelagem relacional via `dim_tags` + tabelas bridge

## Sugestão de uso

- Para documentação técnica detalhada: `docs/DATABASE_METABASE.md`
- Para colar no Excel: `docs/DICIONARIO_TECNICO_METABASE.tsv`
