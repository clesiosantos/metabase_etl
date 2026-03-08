-- EVENTOS (Somente chamados: agente de abertura = zabbix, prioridade = 3 – Média)

-- 1) Volumetria Mensal de Eventos
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_eventos
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE LOWER(metabase_tickets.nome_solicitante) = 'zabbix'
  AND metabase_tickets.prioridade = '3'
  AND COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
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

-- 2) Volumetria por Cliente (Eventos)
SELECT
  metabase_tickets.entidade_cliente AS cliente,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_eventos
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE LOWER(metabase_tickets.nome_solicitante) = 'zabbix'
  AND metabase_tickets.prioridade = '3'
  AND COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
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
ORDER BY total_eventos DESC;