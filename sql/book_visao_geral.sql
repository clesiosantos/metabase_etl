-- VISÃO GERAL

-- 1) Entradas Mensais (Criados por mês - data de abertura)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_criados
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 2) Saídas Mensais (Fechados por mês - data de fechamento)
SELECT
  DATE_FORMAT(metabase_tickets.data_fechamento, '%Y-%m') AS mes_fechamento,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_fechados
FROM metabase_tickets
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.data_fechamento IS NOT NULL
  AND COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_fechamento}}]]
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
GROUP BY DATE_FORMAT(metabase_tickets.data_fechamento, '%Y-%m')
ORDER BY mes_fechamento;

-- 3) Volumetria por Cliente
SELECT
  metabase_tickets.entidade_cliente AS cliente,
  COUNT(DISTINCT metabase_tickets.chamado) AS total
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
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
GROUP BY metabase_tickets.entidade_cliente
ORDER BY total DESC;

-- 4) Volumetria por Grupo (Torre) - usando grupo_solucao
SELECT
  metabase_tickets.grupo_solucao AS torre,
  COUNT(DISTINCT metabase_tickets.chamado) AS total
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
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
GROUP BY metabase_tickets.grupo_solucao
ORDER BY total DESC;

-- 5) Volumetria por Prioridade
SELECT
  metabase_tickets.prioridade,
  COUNT(DISTINCT metabase_tickets.chamado) AS total
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
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
GROUP BY metabase_tickets.prioridade
ORDER BY total DESC;

-- 6) Ranking de Etiquetas (Tags)
SELECT
  dim_tags.name AS etiqueta,
  COUNT(DISTINCT metabase_tickets.chamado) AS total
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
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
GROUP BY dim_tags.name
ORDER BY total DESC;