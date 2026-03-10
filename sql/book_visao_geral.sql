-- BOOK - ABA VISÃO GERAL
-- Cards sugeridos (6): Total Chamados, Backlog, Total Mudanças, Total Problemas, %SLA Resposta, %SLA Solução
-- Cada card abaixo possui sua respectiva consulta de drill-down em formato de tabela.
--
-- Filtros (Field Filters) para cards baseados em tickets:
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_tickets.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_tickets.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_tickets.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_tickets.nome_tecnico_responsavel
-- [[AND {{solicitante}}]]        -> metabase_tickets.nome_solicitante
-- [[AND {{status}}]]             -> metabase_tickets.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_tickets.tipo_solucao
-- [[AND {{tipo_chamado}}]]       -> metabase_tickets.tipo_chamado
-- [[AND {{prioridade}}]]         -> metabase_tickets.prioridade
-- [[AND {{etiqueta}}]]           -> dim_tags.name (via join com bridge_ticket_tags)

-- 1) Total Chamados (card)
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
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 1.1) Drill-down Total Chamados (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.entidade_cliente AS cliente,
  metabase_tickets.grupo_solucao AS torre,
  metabase_tickets.nome_tecnico_responsavel AS tecnico,
  metabase_tickets.nome_solicitante AS solicitante,
  metabase_tickets.data_criacao,
  metabase_tickets.data_solucao,
  metabase_tickets.data_fechamento,
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
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
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 2) Backlog (card) — chamados em aberto
SELECT
  COUNT(DISTINCT metabase_tickets.chamado) AS backlog
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
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 2.1) Drill-down Backlog (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.entidade_cliente AS cliente,
  metabase_tickets.grupo_solucao AS torre,
  metabase_tickets.nome_tecnico_responsavel AS tecnico,
  metabase_tickets.nome_solicitante AS solicitante,
  metabase_tickets.data_criacao,
  metabase_tickets.data_ultima_atualizacao,
  metabase_tickets.dias_sem_atualizacao,
  metabase_tickets.faixa_aging,
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
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
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 3) Total Mudanças (card)
-- Filtros aplicáveis em metabase_changes:
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_changes.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_changes.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_changes.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_changes.agente_solucionador
-- [[AND {{solicitante}}]]        -> metabase_changes.nome_solicitante
-- [[AND {{status}}]]             -> metabase_changes.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_changes.tipo_solucao
-- [[AND {{prioridade}}]]         -> metabase_changes.prioridade
-- Observação: metabase_changes não possui tipo_chamado e não há bridge de tags para usar {{etiqueta}} como Field Filter.
SELECT
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]];

-- 3.1) Drill-down Total Mudanças (tabela)
SELECT
  metabase_changes.chamado AS id,
  metabase_changes.titulo_chamado AS titulo,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.entidade_cliente AS cliente,
  metabase_changes.grupo_solucao AS torre,
  metabase_changes.agente_solucionador AS tecnico,
  metabase_changes.nome_solicitante AS solicitante,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento,
  metabase_changes.tipo_solucao,
  metabase_changes.tags
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
ORDER BY metabase_changes.data_criacao DESC, metabase_changes.chamado DESC;

-- 4) Total Problemas (card)
-- Filtros aplicáveis em metabase_problems:
-- [[AND {{periodo_abertura}}]]   -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]] -> metabase_problems.data_fechamento
-- [[AND {{cliente}}]]            -> metabase_problems.entidade_cliente
-- [[AND {{torre}}]]              -> metabase_problems.grupo_solucao
-- [[AND {{tecnico}}]]            -> metabase_problems.agente_solucionador
-- [[AND {{solicitante}}]]        -> metabase_problems.nome_solicitante
-- [[AND {{status}}]]             -> metabase_problems.status_chamado
-- [[AND {{tipo_solucao}}]]       -> metabase_problems.tipo_solucao
-- [[AND {{prioridade}}]]         -> metabase_problems.prioridade
-- Observação: metabase_problems não possui tipo_chamado e não há bridge de tags para usar {{etiqueta}} como Field Filter.
SELECT
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
WHERE COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]];

-- 4.1) Drill-down Total Problemas (tabela)
SELECT
  metabase_problems.chamado AS id,
  metabase_problems.titulo_chamado AS titulo,
  metabase_problems.status_chamado,
  metabase_problems.prioridade,
  metabase_problems.entidade_cliente AS cliente,
  metabase_problems.grupo_solucao AS torre,
  metabase_problems.agente_solucionador AS tecnico,
  metabase_problems.nome_solicitante AS solicitante,
  metabase_problems.data_criacao,
  metabase_problems.data_solucao,
  metabase_problems.data_fechamento,
  metabase_problems.tipo_solucao,
  metabase_problems.tags
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
WHERE COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
ORDER BY metabase_problems.data_criacao DESC, metabase_problems.chamado DESC;

-- 5) %SLA Resposta (card) — usa sla_atendimento_ok
SELECT
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_atendimento_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_atendimento_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_resposta
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
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 5.1) Drill-down %SLA Resposta (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.entidade_cliente AS cliente,
  metabase_tickets.grupo_solucao AS torre,
  metabase_tickets.nome_tecnico_responsavel AS tecnico,
  metabase_tickets.nome_solicitante AS solicitante,
  metabase_tickets.data_criacao,
  metabase_tickets.limite_atendimento,
  metabase_tickets.tempo_primeiro_atendimento_minutos,
  CASE
    WHEN metabase_tickets.sla_atendimento_ok = 1 THEN 'Dentro do SLA'
    WHEN metabase_tickets.sla_atendimento_ok = 0 THEN 'Fora do SLA'
    ELSE 'Sem medição'
  END AS situacao_sla_resposta,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  AND metabase_tickets.sla_atendimento_ok IS NOT NULL
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
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 6) %SLA Solução (card) — usa sla_solucao_ok
SELECT
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_solucao_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_solucao_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_solucao
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
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]];

-- 6.1) Drill-down %SLA Solução (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.entidade_cliente AS cliente,
  metabase_tickets.grupo_solucao AS torre,
  metabase_tickets.nome_tecnico_responsavel AS tecnico,
  metabase_tickets.nome_solicitante AS solicitante,
  metabase_tickets.data_criacao,
  metabase_tickets.data_solucao,
  metabase_tickets.limite_solucao,
  metabase_tickets.mttr_minutos,
  CASE
    WHEN metabase_tickets.sla_solucao_ok = 1 THEN 'Dentro do SLA'
    WHEN metabase_tickets.sla_solucao_ok = 0 THEN 'Fora do SLA'
    ELSE 'Sem medição'
  END AS situacao_sla_solucao,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE COALESCE(metabase_tickets.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  AND metabase_tickets.sla_solucao_ok IS NOT NULL
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
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;
