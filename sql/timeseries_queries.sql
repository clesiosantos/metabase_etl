-- Bloco de Filtros Padrão Timeseries
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

-- 1. Evolução Mensal: Abertos vs Fechados
SELECT
    dim_calendario.ano_mes AS "Mês",
    COUNT(DISTINCT metabase_tickets.chamado) AS "Abertos",
    COUNT(DISTINCT CASE WHEN status_chamado IN ('Solucionado', 'Fechado') THEN metabase_tickets.chamado END) AS "Fechados"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 2. Tendência de MTTR (Tempo Médio de Solução em Minutos)
SELECT
    dim_calendario.ano_mes AS "Mês",
    ROUND(AVG(mttr_minutos), 2) AS "MTTR Médio (Min)"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND mttr_minutos IS NOT NULL
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 3. Tendência de TTO (Tempo Médio de Resposta em Minutos)
SELECT
    dim_calendario.ano_mes AS "Mês",
    ROUND(AVG(tma_minutos), 2) AS "TTO Médio (Min)"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND tma_minutos IS NOT NULL
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 4. Volume de Abertura por Dia (Últimos 90 dias)
SELECT
    dim_calendario.data AS "Dia",
    COUNT(DISTINCT metabase_tickets.chamado) AS "Qtd Abertos"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND dim_calendario.data >= DATE_SUB(UTC_DATE(), INTERVAL 90 DAY)
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
GROUP BY dim_calendario.data
ORDER BY dim_calendario.data;