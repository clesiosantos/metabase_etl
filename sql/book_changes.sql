-- MUDANÇAS (Change) - Volumetria Mensal
SELECT
  DATE_FORMAT(metabase_changes.data_id, '%Y-%m') AS mes,
  COUNT(*) AS total_mudancas
FROM metabase_changes
WHERE 1=1
  [[AND {{periodo_abertura}}]]  -- Mapear para metabase_changes.data_id
  [[AND {{cliente}}]]           -- Se aplicável, mapear para metabase_changes.entidade_cliente (caso disponível)
GROUP BY DATE_FORMAT(metabase_changes.data_id, '%Y-%m')
ORDER BY mes;