# Documentação: Dashboard Book

Este dashboard consolida visão mensal e rankings por Cliente, Torre, Técnico, além de abas temáticas: Visão Geral, Incidentes, Requisições, Eventos, SLA, Mudanças e Problemas.

## Filtros (Field Filters) — obrigatórios em todos os cards
Mapeie exatamente estes nomes:
- {{periodo_abertura}} → dim_calendario.data
- {{periodo_fechamento}} → metabase_tickets.data_fechamento
- {{cliente}} → metabase_tickets.entidade_cliente
- {{torre}} → metabase_tickets.grupo_solucao
- {{tecnico}} → metabase_tickets.nome_tecnico_responsavel
- {{agente_abertura}} → metabase_tickets.nome_solicitante
- {{agente_solucao}} → metabase_tickets.agente_solucionador
- {{status}} → metabase_tickets.status_chamado
- {{tipo_solucao}} → metabase_tickets.tipo_solucao
- {{tipo_chamado}} → metabase_tickets.tipo_chamado
- {{prioridade}} → metabase_tickets.prioridade
- {{etiqueta}} → dim_tags.name (usa LEFT JOIN ou subselect via bridge_ticket_tags)

## Regras Gerais
- Excluir por padrão: tipo_solucao IN ('Ticket::Duplicado','Ticket::Cancelado') usando COALESCE(tipo_solucao,'') NOT IN (...).
- Sempre JOIN com dim_calendario (data_id) para eixo temporal.
- Evitar duplicidade por etiquetas: quando usar JOIN com bridge/dim_tags, agregue com COUNT(DISTINCT chamado).

## Regras Específicas
- Incidentes: Excluir da volumetria os chamados com agente de abertura = 'zabbix' e prioridade = '3'.
- Eventos: Considerar SOMENTE os chamados com agente de abertura = 'zabbix' e prioridade = '3' (Média).

## Arquivos SQL por Aba
- Visão Geral: sql/book_visao_geral.sql
- Incidentes: sql/book_incidentes.sql
- Requisições de Serviço: sql/book_requisicoes.sql
- Eventos: sql/book_eventos.sql
- SLA: sql/book_sla.sql
- Mudanças (Change): sql/book_changes.sql
- Problemas (Problems): sql/book_problems.sql