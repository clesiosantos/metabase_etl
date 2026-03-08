-- PROBLEMAS (Problems) - Volumetria Mensal
SELECT
  DATE_FORMAT(metabase_problems.data_id, '%Y-%m') AS mes,
  COUNT(*) AS total_problemas
FROM metabase_problems
WHERE 1=1
  [[AND {{periodo_abertura}}]]  -- Mapear para metabase_problems.data_id
  [[AND {{cliente}}]]           -- Se aplicável, mapear para metabase_problems.entidade_cliente (se o campo existir)
GROUP BY DATE_FORMAT(metabase_problems.data_id, '%Y-%m')
ORDER BY mes;