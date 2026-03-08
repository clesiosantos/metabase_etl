-- Bloco de Filtros Padrão Chamado Geral
-- [[AND {{periodo_abertura}}]]   -- Mapear para dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -- Mapear para metabase_tickets.data_fechamento
-- [[AND {{cliente}}]]            -- Mapear para metabase_tickets.entidade_cliente
-- [[AND {{torre}}]]              -- Mapear para metabase_tickets.grupo_solucao
-- [[AND {{tecnico}}]]            -- Mapear para metabase_tickets.nome_tecnico_responsavel
-- [[AND {{solicitante}}]]        -- Mapear para metabase_tickets.nome_solicitante
-- [[AND {{status}}]]             -- Mapear para metabase_tickets.status_chamado
-- [[AND {{tipo_solucao}}]]       -- Mapear para metabase_tickets.tipo_solucao
-- [[AND {{tipo_chamado}}]]       -- Mapear para metabase_tickets.tipo_chamado
-- [[AND {{prioridade}}]]         -- Mapear para metabase_tickets.prioridade
-- [[AND {{etiqueta}}]]           -- Mapear para dim_tags.name

-- 1. Volume Total de Chamados
SELECT COUNT(DISTINCT metabase_tickets.chamado) AS "Total"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 2. Volume por Status
SELECT status_chamado AS "Status", COUNT(DISTINCT metabase_tickets.chamado) AS "Qtd"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY status_chamado
ORDER BY Qtd DESC;

-- 3. Volume por Categoria (Top 10)
SELECT categoria AS "Categoria", COUNT(DISTINCT metabase_tickets.chamado) AS "Qtd"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY categoria
ORDER BY Qtd DESC
LIMIT 10;

-- 4. Volume por Prioridade
SELECT prioridade AS "Prioridade", COUNT(DISTINCT metabase_tickets.chamado) AS "Qtd"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY prioridade
ORDER BY prioridade ASC;

-- 5. Ranking de Etiquetas (Tags)
SELECT dim_tags.name AS "Etiqueta", COUNT(DISTINCT metabase_tickets.chamado) AS "Qtd"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY dim_tags.name
ORDER BY Qtd DESC;