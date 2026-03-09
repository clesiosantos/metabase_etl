-- BOOK - ABA PROBLEMAS (PROBLEMS)
--
-- Filtros (Field Filters):
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_problems.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_problems.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_problems.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_problems.agente_solucionador
-- [[AND {{solicitante}}]]        -> metabase_problems.nome_solicitante
-- [[AND {{status}}]]             -> metabase_problems.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_problems.tipo_solucao
-- [[AND {{prioridade}}]]         -> metabase_problems.prioridade

-- 1) Volumetria Mensal de Problemas (Criados por mês)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
WHERE COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 2) Volumetria por Cliente (Problemas)
SELECT
  metabase_problems.entidade_cliente AS cliente,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
WHERE COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
GROUP BY metabase_problems.entidade_cliente
ORDER BY total_problemas DESC;
