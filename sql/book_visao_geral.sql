Visão Geral: 6 cards (volumes e % SLA) com filtros padronizados e JOIN no calendário.">
-- BOOK - ABA VISÃO GERAL
-- Filtros (Field Filters) em todos os cards:
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_tickets.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_tickets.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_tickets.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_tickets.nome_tecnico_responsavel
-- [[AND {{agente_abertura}}]]    -> metabase_tickets.nome_solicitante
-- [[AND {{agente_solucao}}]]     -> metabase_tickets.agente_solucionador
-- [[AND {{status}}]]             -> metabase_tickets.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_tickets.tipo_solucao
-- [[AND {{tipo_chamado}}]]       -> metabase_tickets.tipo_chamado
-- [[AND {{prioridade}}]]         -> metabase_tickets.prioridade
-- [[AND {{etiqueta}}]]           -> dim_tags.name (via join com bridge_ticket_tags)

-- 1) Volume Total de Chamado (Card)
SELECT
  COUNT(DISTINCT metabase_tickets.chamado) AS total_chamados
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
  [[AND {{etiqueta}}]];

-- 2) Volume Total de Chamados Backlog (Card) - abertos (não solucionados/fechados)
SELECT
  COUNT(DISTINCT metabase_tickets.chamado) AS total_backlog
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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
  [[AND {{etiqueta}}]];

-- 3) Volume Total de Mudanças (Card)
SELECT
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]     -- mapear para dim_calendario.data
  [[AND {{periodo_fechamento}}]]   -- mapear para metabase_changes.data_fechamento
  [[AND {{cliente}}]]              -- mapear para metabase_changes.entidade_cliente
  [[AND {{torre}}]]                -- mapear para metabase_changes.grupo_solucao
  [[AND {{tecnico}}]]              -- mapear para metabase_changes.agente_solucionador
  [[AND {{agente_abertura}}]]      -- mapear para metabase_changes.nome_solicitante
  [[AND {{status}}]]               -- mapear para metabase_changes.status_chamado
  [[AND {{tipo_solucao}}]]         -- mapear para metabase_changes.tipo_solucao
  [[AND {{prioridade}}]];          -- mapear para metabase_changes.prioridade

-- 4) Volume Total de Problemas (Card)
SELECT
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
WHERE 1=1
  [[AND {{periodo_abertura}}]]     -- mapear para dim_calendario.data
  [[AND {{periodo_fechamento}}]]   -- mapear para metabase_problems.data_fechamento
  [[AND {{cliente}}]]              -- se disponível, entidade_cliente em problems
  [[AND {{torre}}]]                -- se disponível, grupo_solucao
  [[AND {{tecnico}}]]              -- mapear para metabase_problems.agente_solucionador
  [[AND {{agente_abertura}}]]      -- mapear para metabase_problems.nome_solicitante
  [[AND {{status}}]]               -- mapear para metabase_problems.status_chamado
  [[AND {{tipo_solucao}}]]         -- mapear para metabase_problems.tipo_solucao
  [[AND {{prioridade}}]];          -- mapear para metabase_problems.prioridade

-- 5) % de SLA de Resposta - Chamado (Card) - TTO
SELECT
  ROUND(
    100 * COUNT(DISTINCT CASE WHEN metabase_tickets.tto_status = 'NO PRAZO' THEN metabase_tickets.chamado END)
    / NULLIF(COUNT(DISTINCT CASE WHEN metabase_tickets.tto_status <> 'SEM SLA' THEN metabase_tickets.chamado END), 0)
  , 2) AS perc_sla_resposta
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
  [[AND {{etiqueta}}]];

-- 6) % de SLA de Solução - Chamado (Card) - TTR
SELECT
  ROUND(
    100 * COUNT(DISTINCT CASE WHEN metabase_tickets.ttr_status = 'NO PRAZO' THEN metabase_tickets.chamado END)
    / NULLIF(COUNT(DISTINCT CASE WHEN metabase_tickets.ttr_status <> 'SEM SLA' THEN metabase_tickets.chamado END), 0)
  , 2) AS perc_sla_solucao
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
  [[AND {{etiqueta}}]];