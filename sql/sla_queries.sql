/* ============================================================
   RELATÓRIO GESTÃO A VISTA - ABA SLA
   ============================================================ */

-- 1. % de SLA de Resposta (TTO) - Últimos 6 meses (Mensal)
SELECT
  DATE_FORMAT(data_criacao, '%Y-%m') AS mes,
  ROUND(
    SUM(CASE WHEN tto_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0) * 100, 
    2
  ) AS percentual_sla_resposta
FROM metabase_tickets
WHERE 1=1
  -- Filtro padrão de exclusão solicitado
  AND servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND data_criacao >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
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
GROUP BY mes
ORDER BY mes ASC;

-- 2. % de SLA de Solução (TTR) - Últimos 6 meses (Mensal)
SELECT
  DATE_FORMAT(data_criacao, '%Y-%m') AS mes,
  ROUND(
    SUM(CASE WHEN ttr_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0) * 100, 
    2
  ) AS percentual_sla_solucao
FROM metabase_tickets
WHERE 1=1
  AND servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND data_criacao >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
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
GROUP BY mes
ORDER BY mes ASC;

-- 3. % SLA Resposta Diário (TTO)
SELECT
  data_id AS dia,
  ROUND(
    SUM(CASE WHEN tto_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0) * 100, 
    2
  ) AS percentual_sla_resposta_diario
FROM metabase_tickets
WHERE 1=1
  AND servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
GROUP BY dia
ORDER BY dia ASC;

-- 4. % SLA de Solução Diário (TTR)
SELECT
  data_id AS dia,
  ROUND(
    SUM(CASE WHEN ttr_status IN ('NO PRAZO', 'EM RISCO') THEN 1 ELSE 0 END) / 
    NULLIF(SUM(CASE WHEN ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0) * 100, 
    2
  ) AS percentual_sla_solucao_diario
FROM metabase_tickets
WHERE 1=1
  AND servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
GROUP BY dia
ORDER BY dia ASC;