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
> - Excluir por padrão "Duplicado/Cancelado": `COALESCE(tipo_solucao,'') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')`.

## Infra / Agendamento (Oracle Linux 9.6)

### Relógio do servidor (IMPORTANTE)
O **systemd timer** usa o relógio do sistema. Se a data/hora estiver errada, o ETL vai rodar fora do horário esperado.

Recomendação:
- **Timezone do servidor:** UTC
- **Sincronização NTP:** habilitada (chrony)

Checklist (no servidor):
- Validar status: `timedatectl`
- Ajustar timezone: `timedatectl set-timezone UTC`
- Habilitar NTP: `timedatectl set-ntp true`
- Verificar serviço: `systemctl status chronyd`

> Observação: o ETL já força `date_default_timezone_set('UTC')` e as conexões MySQL usam `SET SESSION time_zone = '+00:00'`.

### systemd (service + timer)
Arquivos do projeto:
- `ops/systemd/etl-glpi-metabase.service`
- `ops/systemd/etl-glpi-metabase.timer`

Como aplicar (no servidor):
- Copiar o `.service` e `.timer` para `/etc/systemd/system/`
- Recarregar systemd: `systemctl daemon-reload`
- Habilitar e iniciar o timer: `systemctl enable --now etl-glpi-metabase.timer`
- Conferir agendamento: `systemctl list-timers | grep etl-glpi-metabase`

### Rotação de logs (logrotate)
Arquivo do projeto:
- `ops/logrotate/etl-glpi-metabase`

Como aplicar (no servidor):
- Copiar para `/etc/logrotate.d/etl-glpi-metabase`

Logs gerados pelo ETL:
- `ETL_LOG_FILE` no `.env` (padrão atual: `/data/etl-glpi-metabase/logs/etl.log`)
- Regra do logrotate cobre: `/data/etl-glpi-metabase/logs/*.log`

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
- `{{tipo_chamado}}` → **não se aplica** em `metabase_changes`
- `{{etiqueta}}` → **não se aplica como Field Filter padrão** em `metabase_changes` (a tabela possui apenas o campo textual `tags`, sem bridge para `dim_tags`)

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
- `{{tipo_chamado}}` → **não se aplica** em `metabase_problems`
- `{{etiqueta}}` → **não se aplica como Field Filter padrão** em `metabase_problems` (a tabela possui apenas o campo textual `tags`, sem bridge para `dim_tags`)

## Regras Específicas (Zabbix)
- **Incidentes:** excluir da volumetria chamados com `nome_solicitante = 'zabbix'` e `prioridade = '3'`.
- **Eventos:** considerar **somente** chamados com `nome_solicitante = 'zabbix'` e `prioridade = '3'`.
- **Tipo de solução (padrão do dashboard):** manter exclusão padrão por SQL com `COALESCE(tipo_solucao,'') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')`. No Metabase, o filtro `{{tipo_solucao}}` deve trabalhar sobre o conjunto já excluído por essa regra.

## SQLs para implementação (por aba)
Os arquivos abaixo já estão prontos para copiar e colar no Metabase.

- **Visão Geral:** `sql/book_visao_geral.sql`
  - 6 cards: Total Chamados, Backlog, Total Mudanças, Total Problemas, %SLA Resposta, %SLA Solução
  - 6 consultas de **drill-down em tabela**:
    - `1.1) Drill-down Total Chamados`
    - `2.1) Drill-down Backlog`
    - `3.1) Drill-down Total Mudanças`
    - `4.1) Drill-down Total Problemas`
    - `5.1) Drill-down %SLA Resposta`
    - `6.1) Drill-down %SLA Solução`
  - Configuração sugerida no Metabase: em cada card numérico, usar o comportamento de clique para abrir a respectiva consulta de detalhe em formato de tabela, reaproveitando os mesmos filtros do dashboard
- **Incidentes:** `sql/book_incidentes.sql`
  - Relatórios em formato de **gráfico**:
    - Volume Total de Incidente Abertos
    - Volume Total de Incidente Fechado
    - Volume Total de Incidente Backlog
    - Volume Total de Backlog de Incidentes por Status e Aging
    - Volume Total de Incidente com etiqueta Crise
    - Volume Total de Incidente por Criticidade
    - Incidente - Top 10 de Categoria - Mês
  - Drill-downs em tabela para todos os gráficos da aba
  - Regras fixas da aba:
    - `metabase_tickets.tipo_chamado = 'Incidente'`
    - excluir `Ticket::Duplicado` e `Ticket::Cancelado`
    - excluir `nome_solicitante = 'zabbix'` com `prioridade = '3'`
- **Requisições:** `sql/book_requisicoes.sql`
  - Relatórios em formato de **gráfico**:
    - Volume Total de Requisições Abertas
    - Volume Total de Requisições Fechadas
    - Volume Total de Requisições Backlog por Status e Aging
    - Requisição - Top 10 de Categoria
  - Drill-downs em tabela para todos os gráficos da aba
  - Regras fixas da aba:
    - `metabase_tickets.tipo_chamado = 'Requisição'`
    - excluir `Ticket::Duplicado` e `Ticket::Cancelado`
- **Eventos:** `sql/book_eventos.sql`
  - Volumetria mensal e por cliente (regra Zabbix de inclusão)
- **SLA:** `sql/book_sla.sql`
  - %SLA Resposta, %SLA Solução e volumetria Dentro/Fora
- **Mudanças (Changes):** `sql/book_changes.sql`
  - Volumetria mensal e por cliente
- **Problemas (Problems):** `sql/book_problems.sql`
  - Volumetria mensal e por cliente