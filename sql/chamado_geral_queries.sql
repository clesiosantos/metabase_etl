/* ============================================================
   RELATÓRIO GESTÃO A VISTA - ABA CHAMADO GERAL
   ============================================================ */

-- 1. Total de Chamado Fechado
SELECT
  COUNT(*) AS total_fechados
FROM metabase_tickets
WHERE status_chamado = 'Fechado'
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
[[AND {{periodo_fechamento}}]];

-- 2. Total de Chamados Aberto (Backlog Atual)
SELECT
  COUNT(*) AS total_abertos
FROM metabase_tickets
WHERE status_chamado NOT IN ('Solucionado', 'Fechado')
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
[[AND {{periodo_fechamento}}]];

-- 3. Chamados Aberto X Fechado - Visão Diária (Últimos 30 dias)
-- Esta consulta compara quantos chamados foram CRIADOS vs quantos foram FECHADOS por dia.
SELECT
  cal.data AS dia,
  COALESCE(criados.qtd, 0) AS chamados_criados,
  COALESCE(fechados.qtd, 0) AS chamados_fechados
FROM dim_calendario cal
LEFT JOIN (
  SELECT data_id, COUNT(*) AS qtd
  FROM metabase_tickets
  WHERE servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
  GROUP BY data_id
) criados ON criados.data_id = cal.data
LEFT JOIN (
  SELECT DATE(data_fechamento) AS data_f, COUNT(*) AS qtd
  FROM metabase_tickets
  WHERE status_chamado = 'Fechado'
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
  GROUP BY data_f
) fechados ON fechados.data_f = cal.data
WHERE cal.data BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE()
ORDER BY cal.data ASC;