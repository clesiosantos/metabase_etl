-- BOOK - ABA VISÃO GERAL
-- Cards sugeridos (6): Total Chamados, Backlog, Total Mudanças, Total Problemas, %SLA Resposta, %SLA Solução
--
-- Filtros (Field Filters) para cards baseados em tickets:
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_tickets.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_tickets.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_tickets.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_tickets.nome_tecnico_responsavel
-- [[AND {{solicitante}}]]        -> metabase_tickets.nome_solicitante
-- [[AND {{status}}]]             -> metabase_tickets.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_tickets.tipo_solucao
-- [[AND {{tipo_chamado}}]]       -> metabase_tickets.tipo_chamado
-- [[AND {{prioridade}}]]         -> metabase_tickets.prioridade
-- [[AND {{etiqueta}}]]           -> dim_tags.name (via join com bridge_ticket_tags)

-- 1) Total Chamados (card)
SELECT
  COUNT(DISTINCT metabase_tickets.chamado) AS total_chamados
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 2) Backlog (card) — chamados em aberto
SELECT
  COUNT(DISTINCT metabase_tickets.chamado) AS backlog
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
  AND COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 3) Total Mudanças (card)
-- Filtros aplicáveis em metabase_changes:
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_changes.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_changes.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_changes.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_changes.agente_solucionador
-- [[AND {{solicitante}}]]        -> metabase_changes.nome_solicitante
-- [[AND {{status}}]]             -> metabase_changes.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_changes.tipo_solucao
-- [[AND {{prioridade}}]]         -> metabase_changes.prioridade
-- Observação: metabase_changes não possui tipo_chamado e não há bridge de tags para usar {{etiqueta}} como Field Filter.
SELECT
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]];

-- 4) Total Problemas (card)
SELECT
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
WHERE COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{status}}]]
  [[AND {{prioridade}}]];

-- 5) %SLA Resposta (card) — usa sla_atendimento_ok
SELECT
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_atendimento_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_atendimento_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_resposta
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 6) %SLA Solução (card) — usa sla_solucao_ok
SELECT
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_solucao_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_solucao_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_solucao
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];