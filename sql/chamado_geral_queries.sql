/* ============================================================
   RELATÓRIO GESTÃO A VISTA - ABA CHAMADO GERAL
   ============================================================ */

-- 1. Total de Chamado Fechado
SELECT
  COUNT(t.chamado) AS total_fechados
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado = 'Fechado'
[[AND {{cliente}}]]
[[AND {{torre}}]]
[[AND {{tecnico}}]]
[[AND {{status}}]]
[[AND {{tipo_solucao}}]]
[[AND {{periodo_abertura}}]]
[[AND {{periodo_fechamento}}]];

-- 2. Total de Chamados Aberto
SELECT
  COUNT(t.chamado) AS total_abertos
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
[[AND {{cliente}}]]
[[AND {{torre}}]]
[[AND {{tecnico}}]]
[[AND {{status}}]]
[[AND {{tipo_solucao}}]]
[[AND {{periodo_abertura}}]]
[[AND {{periodo_fechamento}}]];

-- 3. Chamados Aberto X Fechado - Visão Diária (30 dias)
SELECT
  cal.data AS dia,
  COALESCE(criados.qtd, 0) AS chamados_criados,
  COALESCE(fechados.qtd, 0) AS chamados_fechados
FROM dim_calendario cal
LEFT JOIN (
  SELECT t.data_id, COUNT(*) AS qtd
  FROM metabase_tickets t
  GROUP BY t.data_id
) criados ON criados.data_id = cal.data
LEFT JOIN (
  SELECT DATE(t.data_fechamento) AS data_f, COUNT(*) AS qtd
  FROM metabase_tickets t
  GROUP BY data_f
) fechados ON fechados.data_f = cal.data
WHERE cal.data BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
ORDER BY cal.data ASC;

-- 4. Exemplo de Ranking por Etiquetas (Tags)
SELECT
  dt.name AS etiqueta,
  COUNT(DISTINCT t.chamado) AS qtd_tickets
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
JOIN bridge_ticket_tags btt ON btt.ticket_id = t.chamado
JOIN dim_tags dt ON dt.tag_id = btt.tag_id
WHERE 1=1
[[AND {{cliente}}]]
[[AND {{periodo_abertura}}]]
GROUP BY dt.name
ORDER BY qtd_tickets DESC;