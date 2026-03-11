-- BOOK - ABA SLA
-- Relatórios solicitados em formato de gráfico:
-- 1) % de SLA de Resposta - Incidente
-- 2) % de SLA de Solução - Incidente
-- 3) % de SLA de Resposta - Requisições
-- 4) % de SLA de Solução - Requisições
--
-- Regras obrigatórias desta aba:
-- - Todos os chamados devem excluir por padrão Ticket::Duplicado e Ticket::Cancelado
-- - Incidentes: excluir chamados com nome_solicitante = 'zabbix' e prioridade = '3'
-- - Eventos: chamados com nome_solicitante = 'zabbix' e prioridade = '3' pertencem à aba Eventos
--
-- Filtros (Field Filters) para gráficos baseados em tickets:
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
--
-- Filtros adicionais de drill-down:
-- [[AND {{categoria_drill}}]]    -> metabase_tickets.servico

-- 1) % de SLA de Resposta - Incidente (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_atendimento_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_atendimento_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_resposta_incidente
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND NOT (LOWER(metabase_tickets.nome_solicitante) = 'zabbix' AND metabase_tickets.prioridade = '3')
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 1.1) Drill-down % de SLA de Resposta - Incidente (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.servico,
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
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND NOT (LOWER(metabase_tickets.nome_solicitante) = 'zabbix' AND metabase_tickets.prioridade = '3')
  AND metabase_tickets.sla_atendimento_ok IS NOT NULL
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
  [[AND {{categoria_drill}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 2) % de SLA de Solução - Incidente (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_solucao_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_solucao_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_solucao_incidente
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND NOT (LOWER(metabase_tickets.nome_solicitante) = 'zabbix' AND metabase_tickets.prioridade = '3')
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 2.1) Drill-down % de SLA de Solução - Incidente (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.servico,
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
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND NOT (LOWER(metabase_tickets.nome_solicitante) = 'zabbix' AND metabase_tickets.prioridade = '3')
  AND metabase_tickets.sla_solucao_ok IS NOT NULL
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
  [[AND {{categoria_drill}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 3) % de SLA de Resposta - Requisições (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_atendimento_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_atendimento_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_resposta_requisicao
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Requisição'
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 3.1) Drill-down % de SLA de Resposta - Requisições (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.servico,
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
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Requisição'
  AND metabase_tickets.sla_atendimento_ok IS NOT NULL
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
  [[AND {{categoria_drill}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 4) % de SLA de Solução - Requisições (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  ROUND(
    100 *
    SUM(CASE WHEN metabase_tickets.sla_solucao_ok = 1 THEN 1 ELSE 0 END)
    /
    NULLIF(SUM(CASE WHEN metabase_tickets.sla_solucao_ok IS NOT NULL THEN 1 ELSE 0 END), 0),
    2
  ) AS percentual_sla_solucao_requisicao
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Requisição'
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
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 4.1) Drill-down % de SLA de Solução - Requisições (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.servico,
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
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Requisição'
  AND metabase_tickets.sla_solucao_ok IS NOT NULL
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
  [[AND {{categoria_drill}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;
