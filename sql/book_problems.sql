-- BOOK - ABA PROBLEMAS (PROBLEMS)
-- Relatórios (gráficos):
-- 1) Volume Total de Problemas abertos
-- 2) Volume Total de Problemas fechados
-- 3) Volume Total de Problemas - Por Causa raiz
-- 4) Volume Total de Problemas - Por Categoria
-- 5) Volume Total de Problemas Backlog - por Status e Aging
--
-- Regras obrigatórias desta aba:
-- - Excluir por padrão Ticket::Duplicado e Ticket::Cancelado
--
-- Filtros (Field Filters) para problemas (mesmos nomes da aba Mudanças, apontando para metabase_problems):
-- [[AND {{periodo_abertura}}]]    -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]]  -> metabase_problems.data_fechamento
-- [[AND {{cliente}}]]             -> metabase_problems.entidade_cliente
-- [[AND {{torre}}]]               -> metabase_problems.grupo_solucionador
-- [[AND {{tecnico}}]]             -> metabase_problems.agente_solucionador
-- [[AND {{solicitante}}]]         -> metabase_problems.nome_solicitante
-- [[AND {{status}}]]              -> metabase_problems.status_chamado
-- [[AND {{tipo_solucao}}]]        -> metabase_problems.tipo_solucao
-- [[AND {{prioridade}}]]          -> metabase_problems.prioridade
-- [[AND {{etiqueta}}]]            -> dim_tags.name (via bridge_problem_tags)
--
-- Filtros adicionais de drill-down:
-- [[AND {{categoria_drill}}]]     -> metabase_problems.categoria
-- [[AND {{causa_raiz_drill}}]]    -> metabase_problems.causa_raiz
-- [[AND {{faixa_aging_drill}}]]   -> (faixa_aging calculada na query)

-- 1) Volume Total de Problemas abertos (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas_abertos
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
WHERE metabase_problems.status_chamado NOT IN ('Solucionado','Fechado')
  AND COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 1.1) Drill-down Volume Total de Problemas abertos (tabela)
SELECT DISTINCT
  metabase_problems.chamado AS id,
  metabase_problems.titulo_chamado AS titulo,
  metabase_problems.status_chamado,
  metabase_problems.prioridade,
  metabase_problems.categoria,
  metabase_problems.causa_raiz,
  metabase_problems.entidade_cliente AS cliente,
  metabase_problems.grupo_solucionador AS torre,
  metabase_problems.agente_solucionador AS agente_solucao,
  metabase_problems.nome_solicitante AS agente_abertura,
  metabase_problems.data_criacao,
  metabase_problems.data_solucao,
  metabase_problems.data_fechamento,
  metabase_problems.tipo_solucao,
  metabase_problems.tags
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
WHERE metabase_problems.status_chamado NOT IN ('Solucionado','Fechado')
  AND COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
ORDER BY metabase_problems.data_criacao DESC, metabase_problems.chamado DESC;

-- 2) Volume Total de Problemas fechados (gráfico)
SELECT
  DATE_FORMAT(metabase_problems.data_fechamento, '%Y-%m') AS mes,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas_fechados
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
WHERE metabase_problems.status_chamado = 'Fechado'
  AND metabase_problems.data_fechamento IS NOT NULL
  AND COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY DATE_FORMAT(metabase_problems.data_fechamento, '%Y-%m')
ORDER BY DATE_FORMAT(metabase_problems.data_fechamento, '%Y-%m');

-- 2.1) Drill-down Volume Total de Problemas fechados (tabela)
SELECT DISTINCT
  metabase_problems.chamado AS id,
  metabase_problems.titulo_chamado AS titulo,
  metabase_problems.status_chamado,
  metabase_problems.prioridade,
  metabase_problems.categoria,
  metabase_problems.causa_raiz,
  metabase_problems.entidade_cliente AS cliente,
  metabase_problems.grupo_solucionador AS torre,
  metabase_problems.agente_solucionador AS agente_solucao,
  metabase_problems.nome_solicitante AS agente_abertura,
  metabase_problems.data_criacao,
  metabase_problems.data_solucao,
  metabase_problems.data_fechamento,
  metabase_problems.tipo_solucao,
  metabase_problems.tags
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
WHERE metabase_problems.status_chamado = 'Fechado'
  AND metabase_problems.data_fechamento IS NOT NULL
  AND COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
ORDER BY metabase_problems.data_fechamento DESC, metabase_problems.chamado DESC;

-- 3) Volume Total de Problemas - Por Causa raiz (gráfico)
SELECT
  COALESCE(metabase_problems.causa_raiz, 'Sem causa raiz') AS causa_raiz,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
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
  [[AND {{etiqueta}}]]
GROUP BY COALESCE(metabase_problems.causa_raiz, 'Sem causa raiz')
ORDER BY total_problemas DESC;

-- 3.1) Drill-down Problemas - Por Causa raiz (tabela)
SELECT DISTINCT
  metabase_problems.chamado AS id,
  metabase_problems.titulo_chamado AS titulo,
  COALESCE(metabase_problems.causa_raiz, 'Sem causa raiz') AS causa_raiz,
  metabase_problems.status_chamado,
  metabase_problems.prioridade,
  metabase_problems.categoria,
  metabase_problems.entidade_cliente AS cliente,
  metabase_problems.grupo_solucionador AS torre,
  metabase_problems.agente_solucionador AS agente_solucao,
  metabase_problems.nome_solicitante AS agente_abertura,
  metabase_problems.data_criacao,
  metabase_problems.data_solucao,
  metabase_problems.data_fechamento,
  metabase_problems.tipo_solucao,
  metabase_problems.tags
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
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
  [[AND {{etiqueta}}]]
  [[AND {{causa_raiz_drill}}]]
ORDER BY metabase_problems.data_criacao DESC, metabase_problems.chamado DESC;

-- 4) Volume Total de Problemas - Por Categoria (gráfico)
SELECT
  COALESCE(metabase_problems.categoria, 'Sem categoria') AS categoria,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
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
  [[AND {{etiqueta}}]]
GROUP BY COALESCE(metabase_problems.categoria, 'Sem categoria')
ORDER BY total_problemas DESC;

-- 4.1) Drill-down Problemas - Por Categoria (tabela)
SELECT DISTINCT
  metabase_problems.chamado AS id,
  metabase_problems.titulo_chamado AS titulo,
  COALESCE(metabase_problems.categoria, 'Sem categoria') AS categoria,
  metabase_problems.causa_raiz,
  metabase_problems.status_chamado,
  metabase_problems.prioridade,
  metabase_problems.entidade_cliente AS cliente,
  metabase_problems.grupo_solucionador AS torre,
  metabase_problems.agente_solucionador AS agente_solucao,
  metabase_problems.nome_solicitante AS agente_abertura,
  metabase_problems.data_criacao,
  metabase_problems.data_solucao,
  metabase_problems.data_fechamento,
  metabase_problems.tipo_solucao,
  metabase_problems.tags
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
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
  [[AND {{etiqueta}}]]
  [[AND {{categoria_drill}}]]
ORDER BY metabase_problems.data_criacao DESC, metabase_problems.chamado DESC;

-- 5) Volume Total de Problemas Backlog - por Status e Aging (gráfico)
SELECT
  metabase_problems.status_chamado,
  CASE
    WHEN metabase_problems.aging_minutos IS NULL THEN 'Não classificado'
    WHEN (metabase_problems.aging_minutos / 1440) <= 3 THEN '0 a 3 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 5 THEN 'Até 5 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 10 THEN 'Até 10 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 15 THEN 'Até 15 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 30 THEN 'Até 30 dias'
    ELSE 'Maior que 30 dias'
  END AS faixa_aging,
  COUNT(DISTINCT metabase_problems.chamado) AS total_problemas
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
WHERE metabase_problems.status_chamado NOT IN ('Solucionado','Fechado')
  AND COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY
  metabase_problems.status_chamado,
  CASE
    WHEN metabase_problems.aging_minutos IS NULL THEN 'Não classificado'
    WHEN (metabase_problems.aging_minutos / 1440) <= 3 THEN '0 a 3 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 5 THEN 'Até 5 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 10 THEN 'Até 10 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 15 THEN 'Até 15 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 30 THEN 'Até 30 dias'
    ELSE 'Maior que 30 dias'
  END
ORDER BY
  metabase_problems.status_chamado,
  FIELD(faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias', 'Não classificado');

-- 5.1) Drill-down Backlog de Problemas - por Status e Aging (tabela)
SELECT DISTINCT
  metabase_problems.chamado AS id,
  metabase_problems.titulo_chamado AS titulo,
  metabase_problems.status_chamado,
  CASE
    WHEN metabase_problems.aging_minutos IS NULL THEN 'Não classificado'
    WHEN (metabase_problems.aging_minutos / 1440) <= 3 THEN '0 a 3 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 5 THEN 'Até 5 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 10 THEN 'Até 10 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 15 THEN 'Até 15 dias'
    WHEN (metabase_problems.aging_minutos / 1440) <= 30 THEN 'Até 30 dias'
    ELSE 'Maior que 30 dias'
  END AS faixa_aging,
  metabase_problems.prioridade,
  metabase_problems.categoria,
  metabase_problems.causa_raiz,
  metabase_problems.entidade_cliente AS cliente,
  metabase_problems.grupo_solucionador AS torre,
  metabase_problems.agente_solucionador AS agente_solucao,
  metabase_problems.nome_solicitante AS agente_abertura,
  metabase_problems.data_criacao,
  metabase_problems.data_ultima_atualizacao,
  metabase_problems.tipo_solucao,
  metabase_problems.tags
FROM metabase_problems
JOIN dim_calendario ON dim_calendario.data = metabase_problems.data_id
LEFT JOIN bridge_problem_tags ON bridge_problem_tags.problem_id = metabase_problems.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_problem_tags.tag_id
WHERE metabase_problems.status_chamado NOT IN ('Solucionado','Fechado')
  AND COALESCE(metabase_problems.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
  [[AND {{faixa_aging_drill}}]]
ORDER BY metabase_problems.data_criacao DESC, metabase_problems.chamado DESC;
