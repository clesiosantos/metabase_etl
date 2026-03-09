# Documentação: Dashboard BOOK (Metabase)

Este dashboard consolida visão mensal e rankings do GLPI (DW) com abas:
- Visão Geral
- Incidentes
- Requisições de Serviço
- Eventos
- SLA
- Mudanças (Changes)
- Problemas (Problems)

> **Padrões obrigatórios**
> - Operação em **UTC**.
> - Sempre usar `JOIN dim_calendario ON dim_calendario.data = <tabela>.data_id` para o filtro de período de abertura.
> - Para evitar duplicidade ao usar tags: `COUNT(DISTINCT <id>)`.
> - Excluir por padrão “Duplicado/Cancelado”: `COALESCE(tipo_solucao,'') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')`.

## Filtros (Field Filters) — padrão do BOOK
Crie os filtros no Metabase com exatamente estes nomes e mapeamentos.

### Tickets (metabase_tickets)
- `{{periodo_abertura}}` → `dim_calendario.data`
- `{{periodo_fechamento}}` → `metabase_tickets.data_fechamento`
- `{{cliente}}` → `metabase_tickets.entidade_cliente`
- `{{torre}}` → `metabase_tickets.grupo_solucao`
- `{{tecnico}}` → `metabase_tickets.nome_tecnico_responsavel`
- `{{solicitante}}` → `metabase_tickets.nome_solicitante`
- `{{status}}` → `metabase_tickets.status_chamado`
- `{{tipo_solucao}}` → `metabase_tickets.tipo_solucao`
- `{{tipo_chamado}}` → `metabase_tickets.tipo_chamado`
- `{{prioridade}}` → `metabase_tickets.prioridade`
- `{{etiqueta}}` → `dim_tags.name` (via `LEFT JOIN bridge_ticket_tags` + `LEFT JOIN dim_tags`)

### Mudanças (metabase_changes)
- `{{periodo_abertura}}` → `dim_calendario.data`
- `{{periodo_fechamento}}` → `metabase_changes.data_fechamento`
- `{{cliente}}` → `metabase_changes.entidade_cliente`
- `{{torre}}` → `metabase_changes.grupo_solucao`
- `{{tecnico}}` → `metabase_changes.agente_solucionador`
- `{{solicitante}}` → `metabase_changes.nome_solicitante`
- `{{status}}` → `metabase_changes.status_chamado`
- `{{tipo_solucao}}` → `metabase_changes.tipo_solucao`
- `{{prioridade}}` → `metabase_changes.prioridade`

### Problemas (metabase_problems)
- `{{periodo_abertura}}` → `dim_calendario.data`
- `{{periodo_fechamento}}` → `metabase_problems.data_fechamento`
- `{{cliente}}` → `metabase_problems.entidade_cliente`
- `{{torre}}` → `metabase_problems.grupo_solucao`
- `{{tecnico}}` → `metabase_problems.agente_solucionador`
- `{{solicitante}}` → `metabase_problems.nome_solicitante`
- `{{status}}` → `metabase_problems.status_chamado`
- `{{tipo_solucao}}` → `metabase_problems.tipo_solucao`
- `{{prioridade}}` → `metabase_problems.prioridade`

## Regras Específicas (Zabbix)
- **Incidentes:** excluir da volumetria chamados com `nome_solicitante = 'zabbix'` e `prioridade = '3'`.
- **Eventos:** considerar **somente** chamados com `nome_solicitante = 'zabbix'` e `prioridade = '3'`.

## SQLs para implementação (por aba)
Os arquivos abaixo já estão prontos para copiar e colar no Metabase.

- **Visão Geral:** `sql/book_visao_geral.sql`
  - 6 cards: Total Chamados, Backlog, Total Mudanças, Total Problemas, %SLA Resposta, %SLA Solução
- **Incidentes:** `sql/book_incidentes.sql`
  - Volumetria mensal e por cliente (com regra Zabbix de exclusão)
- **Requisições:** `sql/book_requisicoes.sql`
  - Volumetria mensal e por cliente (tipo_chamado = 'Requisição')
- **Eventos:** `sql/book_eventos.sql`
  - Volumetria mensal e por cliente (regra Zabbix de inclusão)
- **SLA:** `sql/book_sla.sql`
  - %SLA Resposta, %SLA Solução e volumetria Dentro/Fora
- **Mudanças (Changes):** `sql/book_changes.sql`
  - Volumetria mensal e por cliente
- **Problemas (Problems):** `sql/book_problems.sql`
  - Volumetria mensal e por cliente
