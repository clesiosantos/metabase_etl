-- 1. % de SLA de Resposta (TTO)
SELECT
    DATE_FORMAT(metabase_tickets.data_id, '%Y-%m') AS mes,
    ROUND(
        (SUM(CASE WHEN metabase_tickets.tto_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN metabase_tickets.tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0)) * 100, 
    2) AS perc_sla_resposta
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE (metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado') OR metabase_tickets.tipo_solucao IS NULL)
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
GROUP BY mes
ORDER BY mes;

-- 2. % de SLA de Solução (TTR)
SELECT
    DATE_FORMAT(metabase_tickets.data_id, '%Y-%m') AS mes,
    ROUND(
        (SUM(CASE WHEN metabase_tickets.ttr_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN metabase_tickets.ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0)) * 100, 
    2) AS perc_sla_solucao
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE (metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado') OR metabase_tickets.tipo_solucao IS NULL)
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
GROUP BY mes
ORDER BY mes;