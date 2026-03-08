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

-- 1. Total de Chamado Fechado (Card)
-- Condição: Status IN ('Solucionado', 'Fechado')
SELECT COUNT(DISTINCT metabase_tickets.chamado) AS "Total Fechados"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND metabase_tickets.status_chamado IN ('Solucionado', 'Fechado')
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

-- 1.1 Detalhe de Chamados Fechados (Consulta de Clique)
SELECT 
    chamado AS "ID",
    titulo_chamado AS "Título",
    status_chamado AS "Status",
    data_criacao AS "Criação",
    data_solucao AS "Solução",
    agente_solucionador AS "Técnico Solucionador"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND metabase_tickets.status_chamado IN ('Solucionado', 'Fechado')
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
ORDER BY data_solucao DESC;

-- 2. Total de Chamados Aberto (Card)
-- Condição: Status NOT IN ('Solucionado', 'Fechado')
SELECT COUNT(DISTINCT metabase_tickets.chamado) AS "Total Abertos"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
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

-- 2.1 Detalhe de Chamados Abertos (Consulta de Clique)
SELECT 
    chamado AS "ID",
    titulo_chamado AS "Título",
    status_chamado AS "Status",
    data_criacao AS "Criação",
    nome_tecnico_responsavel AS "Técnico Atribuído",
    aging_minutos AS "Aging (Min)"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
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
ORDER BY data_criacao ASC;

-- 3. Chamados Aberto X Fechado - Visão Diária (Últimos 30 dias)
SELECT
    dim_calendario.data AS "Dia",
    COUNT(DISTINCT CASE WHEN status_chamado NOT IN ('Solucionado', 'Fechado') THEN metabase_tickets.chamado END) AS "Abertos",
    COUNT(DISTINCT CASE WHEN status_chamado IN ('Solucionado', 'Fechado') THEN metabase_tickets.chamado END) AS "Fechados"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags btt ON btt.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = btt.tag_id
WHERE metabase_tickets.tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
  AND dim_calendario.data >= DATE_SUB(UTC_DATE(), INTERVAL 30 DAY)
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