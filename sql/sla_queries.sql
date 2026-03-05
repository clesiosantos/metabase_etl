-- 1. % de SLA de Resposta (TTO)
SELECT
    DATE_FORMAT(t.data_id, '%Y-%m') AS mes,
    ROUND(
        (SUM(CASE WHEN t.tto_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN t.tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0)) * 100, 
    2) AS perc_sla_resposta
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE (t.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado') OR t.tipo_solucao IS NULL)
  [[AND {{periodo_abertura}}]] -- Mapear para c.data no Metabase
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
GROUP BY mes
ORDER BY mes;

-- 2. % de SLA de Solução (TTR)
SELECT
    DATE_FORMAT(t.data_id, '%Y-%m') AS mes,
    ROUND(
        (SUM(CASE WHEN t.ttr_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN t.ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0)) * 100, 
    2) AS perc_sla_solucao
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE (t.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado') OR t.tipo_solucao IS NULL)
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
GROUP BY mes
ORDER BY mes;