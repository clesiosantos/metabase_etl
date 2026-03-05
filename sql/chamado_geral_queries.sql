-- 1. Distribuição por Disciplina de Solução
SELECT 
    COALESCE(t.disciplina_solucao, 'Não Informado') AS disciplina,
    COUNT(*) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]] -- Mapear para c.data no Metabase
  [[AND {{cliente}}]]
GROUP BY t.disciplina_solucao
ORDER BY qtd DESC;

-- 2. Ranking de Modelos de Solução (Top 10)
SELECT 
    COALESCE(t.modelo_solucao, 'Não Informado') AS modelo,
    COUNT(*) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY t.modelo_solucao
ORDER BY qtd DESC
LIMIT 10;

-- 3. Volume por Etiquetas (Tags) - Usando a Ponte e Calendário
SELECT
    dt.name AS tag,
    COUNT(DISTINCT t.chamado) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
JOIN bridge_ticket_tags btt ON btt.ticket_id = t.chamado
JOIN dim_tags dt ON dt.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY dt.name
ORDER BY qtd DESC;

-- 4. Listagem Geral com Detalhes de Solução
SELECT 
    t.chamado,
    t.titulo_chamado,
    t.status_chamado,
    t.data_criacao,
    t.data_solucao,
    t.disciplina_solucao,
    t.modelo_solucao,
    t.agente_solucionador,
    t.entidade_cliente
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE 1=1
  [[AND {{periodo}}]]
  [[AND {{status}}]]
  [[AND {{cliente}}]]
ORDER BY t.data_criacao DESC;