-- 1. Distribuição por Disciplina de Solução
SELECT 
    COALESCE(metabase_tickets.disciplina_solucao, 'Não Informado') AS disciplina,
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY metabase_tickets.disciplina_solucao
ORDER BY qtd DESC;

-- 2. Ranking de Modelos de Solução (Top 10)
SELECT 
    COALESCE(metabase_tickets.modelo_solucao, 'Não Informado') AS modelo,
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY metabase_tickets.modelo_solucao
ORDER BY qtd DESC
LIMIT 10;

-- 3. Volume por Etiquetas (Tags) - Usando a Ponte e Calendário sem aliases
SELECT
    dim_tags.name AS tag,
    COUNT(DISTINCT metabase_tickets.chamado) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE 1=1
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY dim_tags.name
ORDER BY qtd DESC;

-- 4. Listagem Geral com Detalhes de Solução
SELECT 
    metabase_tickets.chamado,
    metabase_tickets.titulo_chamado,
    metabase_tickets.status_chamado,
    metabase_tickets.data_criacao,
    metabase_tickets.data_solucao,
    metabase_tickets.disciplina_solucao,
    metabase_tickets.modelo_solucao,
    metabase_tickets.agente_solucionador,
    metabase_tickets.entidade_cliente
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE 1=1
  [[AND {{periodo}}]]
  [[AND {{status}}]]
  [[AND {{cliente}}]]
ORDER BY metabase_tickets.data_criacao DESC;