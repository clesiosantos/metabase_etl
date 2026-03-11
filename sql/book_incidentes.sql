-- BOOK - ABA INCIDENTES
-- Relatórios solicitados em formato de gráfico:
-- 1) Volume Total de Incidente Abertos
-- 2) Volume Total de Incidente Fechado
-- 3) Volume Total de Incidente Backlog
-- 4) Volume Total de Backlog de Incidentes - por Status e Aging
-- 5) Volume Total de Incidente com etiqueta Crise
-- 6) Volume Total de Incidente por Criticidade
-- 7) Incidente - Top 10 de Categoria - Mês
--
-- Regras obrigatórias desta aba:
-- - Sempre considerar apenas metabase_tickets.tipo_chamado = 'Incidente'
-- - Excluir por padrão Ticket::Duplicado e Ticket::Cancelado
-- - Regra Incidentes (Zabbix): chamados com nome_solicitante = 'zabbix' e prioridade = '3' NÃO entram na volumetria de Incidentes
-- - Regra Eventos: chamados com nome_solicitante = 'zabbix' e prioridade = '3' pertencem à aba Eventos
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
-- [[AND {{faixa_aging_drill}}]]  -> metabase_tickets.faixa_aging
-- [[AND {{categoria_drill}}]]    -> metabase_tickets.categoria

-- 1) Volume Total de Incidente Abertos (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes_abertos
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

-- 1.1) Drill-down Volume Total de Incidente Abertos (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.categoria,
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
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 2) Volume Total de Incidente Fechado (gráfico)
SELECT
  DATE_FORMAT(metabase_tickets.data_fechamento, '%Y-%m') AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes_fechados
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND metabase_tickets.status_chamado IN ('Solucionado','Fechado')
  AND metabase_tickets.data_fechamento IS NOT NULL
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
GROUP BY DATE_FORMAT(metabase_tickets.data_fechamento, '%Y-%m')
ORDER BY DATE_FORMAT(metabase_tickets.data_fechamento, '%Y-%m');

-- 2.1) Drill-down Volume Total de Incidente Fechado (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.categoria,
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
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND metabase_tickets.status_chamado IN ('Solucionado','Fechado')
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
ORDER BY metabase_tickets.data_fechamento DESC, metabase_tickets.chamado DESC;

-- 3) Volume Total de Incidente Backlog (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes_backlog
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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

-- 3.1) Drill-down Volume Total de Incidente Backlog (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.categoria,
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
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 4) Volume Total de Backlog de Incidentes - por Status e Aging (gráfico)
SELECT
  metabase_tickets.status_chamado,
  COALESCE(metabase_tickets.faixa_aging, 'Não classificado') AS faixa_aging,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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
GROUP BY
  metabase_tickets.status_chamado,
  COALESCE(metabase_tickets.faixa_aging, 'Não classificado')
ORDER BY
  metabase_tickets.status_chamado,
  FIELD(faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias', 'Não classificado');

-- 4.1) Drill-down Backlog de Incidentes - por Status e Aging (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.status_chamado,
  COALESCE(metabase_tickets.faixa_aging, 'Não classificado') AS faixa_aging,
  metabase_tickets.prioridade,
  metabase_tickets.categoria,
  metabase_tickets.entidade_cliente AS cliente,
  metabase_tickets.grupo_solucao AS torre,
  metabase_tickets.nome_tecnico_responsavel AS tecnico,
  metabase_tickets.nome_solicitante AS solicitante,
  metabase_tickets.data_criacao,
  metabase_tickets.data_ultima_atualizacao,
  metabase_tickets.dias_sem_atualizacao,
  metabase_tickets.tipo_solucao,
  metabase_tickets.tags
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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
  [[AND {{faixa_aging_drill}}]]
ORDER BY metabase_tickets.status_chamado, metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 5) Volume Total de Incidente com etiqueta Crise (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes_crise
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND LOWER(dim_tags.name) = 'crise'
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

-- 5.1) Drill-down Volume Total de Incidente com etiqueta Crise (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.status_chamado,
  metabase_tickets.prioridade,
  metabase_tickets.categoria,
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
WHERE metabase_tickets.tipo_chamado = 'Incidente'
  AND LOWER(dim_tags.name) = 'crise'
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
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 6) Volume Total de Incidente por Criticidade (gráfico)
SELECT
  COALESCE(metabase_tickets.prioridade, 'Não informada') AS criticidade,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes
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
GROUP BY COALESCE(metabase_tickets.prioridade, 'Não informada')
ORDER BY total_incidentes DESC;

-- 6.1) Drill-down Volume Total de Incidente por Criticidade (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  COALESCE(metabase_tickets.prioridade, 'Não informada') AS criticidade,
  metabase_tickets.status_chamado,
  metabase_tickets.categoria,
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
ORDER BY metabase_tickets.prioridade, metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;

-- 7) Incidente - Top 10 de Categoria - Mês (gráfico)
SELECT
  COALESCE(metabase_tickets.categoria, 'Sem categoria') AS categoria,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_incidentes
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
GROUP BY COALESCE(metabase_tickets.categoria, 'Sem categoria')
ORDER BY total_incidentes DESC
LIMIT 10;

-- 7.1) Drill-down Incidente - Top 10 de Categoria - Mês (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  COALESCE(metabase_tickets.categoria, 'Sem categoria') AS categoria,
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
  [[AND {{categoria_drill}}]]
ORDER BY metabase_tickets.data_criacao DESC, metabase_tickets.chamado DESC;
