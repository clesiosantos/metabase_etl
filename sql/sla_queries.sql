-- Bloco de Filtros Padrão SLA
-- [[AND {{periodo_abertura}}]]   -- Mapear para dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -- Mapear para metabase_tickets.data_fechamento
-- [[AND {{cliente}}]]            -- Mapear para metabase_tickets.entidade_cliente
-- [[AND {{torre}}]]              -- Mapear para metabase_tickets.grupo_solucao
-- [[AND {{tecnico}}]]            -- Mapear para metabase_tickets.nome_tecnico_responsavel
-- [[AND {{agente_abertura}}]]    -- Mapear para metabase_tickets.nome_solicitante
-- [[AND {{agente_solucao}}]]     -- Mapear para metabase_tickets.agente_solucionador
-- [[AND {{status}}]]             -- Mapear para metabase_tickets.status_chamado
-- [[AND {{tipo_solucao}}]]       -- Mapear para metabase_tickets.tipo_solucao
-- [[AND {{tipo_chamado}}]]       -- Mapear para metabase_tickets.tipo_chamado
-- [[AND {{prioridade}}]]         -- Mapear para metabase_tickets.prioridade
-- [[AND {{etiqueta}}]]           -- Mapear para dim_tags.name (via subquery abaixo)

-- 1. % de SLA de Resposta (TTO) - Evolução Mensal
SELECT
    dim_calendario.ano_mes AS "Mês",
    ROUND(100 * SUM(CASE WHEN tto_status = 'NO PRAZO' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0), 2) AS "% SLA Resposta"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
  -- Filtro de Etiqueta via Tabela de Ponte
  [[AND metabase_tickets.chamado IN (
      SELECT btt.ticket_id 
      FROM bridge_ticket_tags btt 
      JOIN dim_tags dt ON dt.tag_id = btt.tag_id 
      WHERE {{etiqueta}}
  )]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 2. % de SLA de Solução (TTR) - Evolução Mensal
SELECT
    dim_calendario.ano_mes AS "Mês",
    ROUND(100 * SUM(CASE WHEN ttr_status = 'NO PRAZO' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0), 2) AS "% SLA Solução"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
  -- Filtro de Etiqueta via Tabela de Ponte
  [[AND metabase_tickets.chamado IN (
      SELECT btt.ticket_id 
      FROM bridge_ticket_tags btt 
      JOIN dim_tags dt ON dt.tag_id = btt.tag_id 
      WHERE {{etiqueta}}
  )]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 3. % SLA Resposta Diário
SELECT
    dim_calendario.data AS "Dia",
    ROUND(100 * SUM(CASE WHEN tto_status = 'NO PRAZO' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN tto_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0), 2) AS "% SLA Resposta"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
  -- Filtro de Etiqueta via Tabela de Ponte
  [[AND metabase_tickets.chamado IN (
      SELECT btt.ticket_id 
      FROM bridge_ticket_tags btt 
      JOIN dim_tags dt ON dt.tag_id = btt.tag_id 
      WHERE {{etiqueta}}
  )]]
GROUP BY dim_calendario.data
ORDER BY dim_calendario.data;

-- 4. % SLA de Solução Diário
SELECT
    dim_calendario.data AS "Dia",
    ROUND(100 * SUM(CASE WHEN ttr_status = 'NO PRAZO' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN ttr_status <> 'SEM SLA' THEN 1 ELSE 0 END), 0), 2) AS "% SLA Solução"
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE tipo_solucao NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
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
  -- Filtro de Etiqueta via Tabela de Ponte
  [[AND metabase_tickets.chamado IN (
      SELECT btt.ticket_id 
      FROM bridge_ticket_tags btt 
      JOIN dim_tags dt ON dt.tag_id = btt.tag_id 
      WHERE {{etiqueta}}
  )]]
GROUP BY dim_calendario.data
ORDER BY dim_calendario.data;