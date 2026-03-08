-- SLA (Percentuais) - Book

-- 1) % SLA Resposta (TTO) - Mensal
SELECT
  dim_calendario.ano_mes AS mes,
  ROUND(
    100 * COUNT(DISTINCT CASE WHEN metabase_tickets.tto_status = 'NO PRAZO' THEN metabase_tickets.chamado END)
    / NULLIF(COUNT(DISTINCT CASE WHEN metabase_tickets.tto_status <> 'SEM SLA' THEN metabase_tickets.chamado END), 0)
  , 2) AS perc_sla_resposta
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
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 2) % SLA Solução (TTR) - Mensal
SELECT
  dim_calendario.ano_mes AS mes,
  ROUND(
    100 * COUNT(DISTINCT CASE WHEN metabase_tickets.ttr_status = 'NO PRAZO' THEN metabase_tickets.chamado END)
    / NULLIF(COUNT(DISTINCT CASE WHEN metabase_tickets.ttr_status <> 'SEM SLA' THEN metabase_tickets.chamado END), 0)
  , 2) AS perc_sla_solucao
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
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;