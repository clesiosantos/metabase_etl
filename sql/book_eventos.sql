-- BOOK - ABA EVENTOS
-- Relatórios solicitados em formato de gráfico:
-- 1) Volume Total de Eventos Abertas
-- 2) Volume Total de Eventos Fechado
-- 3) Volume Total de Eventos Backlog
-- 4) Evento - Top 10 de Categoria
--
-- Regras obrigatórias desta aba:
-- - Considerar SOMENTE chamados com nome_solicitante = 'integracao.api' e prioridade = '3'
-- - Excluir por padrão Ticket::Duplicado e Ticket::Cancelado
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
-- [[AND {{categoria_drill}}]]    -> metabase_tickets.categoria

-- 1) Volume Total de Eventos Abertas (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_eventos_abertos
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
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

-- 1.1) Drill-down Volume Total de Eventos Abertas (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
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
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
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

-- 2) Volume Total de Eventos Fechado (gráfico)
SELECT
  DATE_FORMAT(metabase_tickets.data_fechamento, '%Y-%m') AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_eventos_fechados
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
  AND metabase_tickets.status_chamado IN ('Solucionado','Fechado')
  AND metabase_tickets.data_fechamento IS NOT NULL
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

-- 2.1) Drill-down Volume Total de Eventos Fechado (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
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
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
  AND metabase_tickets.status_chamado IN ('Solucionado','Fechado')
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

-- 3) Volume Total de Eventos Backlog (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_eventos_backlog
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
  AND metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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

-- 3.1) Drill-down Volume Total de Eventos Backlog (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  metabase_tickets.tipo_chamado,
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
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
  AND metabase_tickets.status_chamado NOT IN ('Solucionado','Fechado')
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

-- 4) Evento - Top 10 de Categoria (gráfico)
SELECT
  COALESCE(metabase_tickets.categoria, 'Sem categoria') AS categoria,
  COUNT(DISTINCT metabase_tickets.chamado) AS total_eventos
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
LEFT JOIN bridge_ticket_tags ON bridge_ticket_tags.ticket_id = metabase_tickets.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_ticket_tags.tag_id
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
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
ORDER BY total_eventos DESC
LIMIT 10;

-- 4.1) Drill-down Evento - Top 10 de Categoria (tabela)
SELECT DISTINCT
  metabase_tickets.chamado AS id,
  metabase_tickets.titulo_chamado AS titulo,
  COALESCE(metabase_tickets.categoria, 'Sem categoria') AS categoria,
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
WHERE LOWER(metabase_tickets.nome_solicitante) = 'integracao.api'
  AND metabase_tickets.prioridade = '3'
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
