-- 1. Distribuição por Disciplina de Solução
SELECT 
    COALESCE(disciplina_solucao, 'Não Informado') AS disciplina,
    COUNT(*) AS qtd
FROM metabase_tickets
WHERE status_chamado IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY disciplina_solucao
ORDER BY qtd DESC;

-- 2. Ranking de Modelos de Solução (Top 10)
SELECT 
    COALESCE(modelo_solucao, 'Não Informado') AS modelo,
    COUNT(*) AS qtd
FROM metabase_tickets
WHERE status_chamado IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY modelo_solucao
ORDER BY qtd DESC
LIMIT 10;

-- 3. Volume por Etiquetas (Tags) - Usando a Ponte
SELECT
    dt.name AS tag,
    COUNT(DISTINCT t.chamado) AS qtd
FROM metabase_tickets t
JOIN bridge_ticket_tags btt ON btt.ticket_id = t.chamado
JOIN dim_tags dt ON dt.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY dt.name
ORDER BY qtd DESC;

-- 4. Listagem Geral com Detalhes de Solução
SELECT 
    chamado,
    titulo_chamado,
    status_chamado,
    data_criacao,
    data_solucao,
    disciplina_solucao,
    modelo_solucao,
    agente_solucionador,
    entidade_cliente
FROM metabase_tickets
WHERE 1=1
  [[AND {{periodo}}]]
  [[AND {{status}}]]
  [[AND {{cliente}}]]
ORDER BY data_criacao DESC;