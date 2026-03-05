/* ============================================================
   RELATÓRIO GESTÃO A VISTA - ABA SLA
   ============================================================ */

-- 1. % de SLA de Resposta (TTO) - Últimos 6 meses
SELECT
  c.ano_mes AS mes,
  ROUND(
    SUM(CASE WHEN t.tto_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN t.tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0) * 100, 
    2
  ) AS percentual_sla_resposta
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.data_criacao >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
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
[[AND {{periodo_abertura}}]]
[[AND {{periodo_fechamento}}]]
GROUP BY c.ano_mes
ORDER BY c.ano_mes ASC;

-- 2. % de SLA de Solução (TTR) - Últimos 6 meses
SELECT
  c.ano_mes AS mes,
  ROUND(
    SUM(CASE WHEN t.ttr_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN t.ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0) * 100, 
    2
  ) AS percentual_sla_solucao
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.data_criacao >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
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
[[AND {{periodo_abertura}}]]
[[AND {{periodo_fechamento}}]]
GROUP BY c.ano_mes
ORDER BY c.ano_mes ASC;