-- BOOK - ABA MUDANÇAS (CHANGES)
-- Relatórios solicitados em formato de gráfico:
-- 1) Volume Total de Mudanças Abertas
-- 2) Volume Total de Mudanças Fechadas
-- 3) Top 10 - Por Classificação Tecnica
-- 4) Volume Total de Mudanças - Por Categoria
-- 5) % de Mudança Executada Com sucesso
--
-- Regras obrigatórias desta aba:
-- - Excluir por padrão Ticket::Duplicado e Ticket::Cancelado
--
-- Filtros (Field Filters) para mudanças:
-- [[AND {{periodo_abertura}}]]    -> dim_calendario.data
-- [[AND {{periodo_fechamento}}]]  -> metabase_changes.data_fechamento
-- [[AND {{cliente}}]]             -> metabase_changes.entidade_cliente
-- [[AND {{torre}}]]               -> metabase_changes.grupo_solucionador
-- [[AND {{tecnico}}]]             -> metabase_changes.agente_solucionador
-- [[AND {{agente_abertura}}]]     -> metabase_changes.nome_solicitante
-- [[AND {{agente_solucao}}]]      -> metabase_changes.agente_solucionador
-- [[AND {{status}}]]              -> metabase_changes.status_chamado
-- [[AND {{tipo_solucao}}]]        -> metabase_changes.tipo_solucao
-- [[AND {{prioridade}}]]          -> metabase_changes.prioridade
-- [[AND {{etiqueta}}]]            -> dim_tags.name (via bridge_change_tags)
--
-- Observações:
-- - metabase_changes não possui tipo_chamado (a aba já é Mudanças)
-- - "Classificação Tecnica" foi mapeada para metabase_changes.tipo_atividade
-- - Status de Mudanças (DW): Novo, Avaliação, Aprovação, Aceito, Pendente, Testando, Qualificação, Revisão, Aplicado, Cancelado, Recusado, Fechado
-- - % de sucesso: considera mudanças Fechadas que NÃO possuem a tag "Mudança::Fechado Sem Sucesso"
--
-- Filtros adicionais de drill-down:
-- [[AND {{classificacao_tecnica_drill}}]] -> metabase_changes.tipo_atividade
-- [[AND {{categoria_drill}}]]             -> metabase_changes.categoria

-- 1) Volume Total de Mudanças Abertas (gráfico)
SELECT
  dim_calendario.ano_mes AS mes,
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas_abertas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE metabase_changes.status_chamado NOT IN ('Aplicado','Cancelado','Recusado','Fechado')
  AND COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY dim_calendario.ano_mes
ORDER BY dim_calendario.ano_mes;

-- 1.1) Drill-down Volume Total de Mudanças Abertas (tabela)
SELECT
  metabase_changes.chamado AS id,
  metabase_changes.titulo_chamado AS titulo,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.categoria,
  metabase_changes.tipo_atividade AS classificacao_tecnica,
  metabase_changes.entidade_cliente AS cliente,
  metabase_changes.grupo_solucionador AS torre,
  metabase_changes.agente_solucionador AS agente_solucao,
  metabase_changes.nome_solicitante AS agente_abertura,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento,
  metabase_changes.tipo_solucao,
  metabase_changes.tags
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE metabase_changes.status_chamado NOT IN ('Aplicado','Cancelado','Recusado','Fechado')
  AND COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
ORDER BY metabase_changes.data_criacao DESC, metabase_changes.chamado DESC;

-- 2) Volume Total de Mudanças Fechadas (gráfico)
SELECT
  DATE_FORMAT(metabase_changes.data_fechamento, '%Y-%m') AS mes,
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas_fechadas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE metabase_changes.status_chamado = 'Fechado'
  AND metabase_changes.data_fechamento IS NOT NULL
  AND COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY DATE_FORMAT(metabase_changes.data_fechamento, '%Y-%m')
ORDER BY DATE_FORMAT(metabase_changes.data_fechamento, '%Y-%m');

-- 2.1) Drill-down Volume Total de Mudanças Fechadas (tabela)
SELECT
  metabase_changes.chamado AS id,
  metabase_changes.titulo_chamado AS titulo,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.categoria,
  metabase_changes.tipo_atividade AS classificacao_tecnica,
  metabase_changes.entidade_cliente AS cliente,
  metabase_changes.grupo_solucionador AS torre,
  metabase_changes.agente_solucionador AS agente_solucao,
  metabase_changes.nome_solicitante AS agente_abertura,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento,
  metabase_changes.tipo_solucao,
  metabase_changes.tags
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE metabase_changes.status_chamado = 'Fechado'
  AND COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
ORDER BY metabase_changes.data_fechamento DESC, metabase_changes.chamado DESC;

-- 3) Top 10 - Por Classificação Tecnica (gráfico)
SELECT
  COALESCE(metabase_changes.tipo_atividade, 'Sem classificação') AS classificacao_tecnica,
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY COALESCE(metabase_changes.tipo_atividade, 'Sem classificação')
ORDER BY total_mudancas DESC
LIMIT 10;

-- 3.1) Drill-down Top 10 - Por Classificação Tecnica (tabela)
SELECT
  metabase_changes.chamado AS id,
  metabase_changes.titulo_chamado AS titulo,
  COALESCE(metabase_changes.tipo_atividade, 'Sem classificação') AS classificacao_tecnica,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.categoria,
  metabase_changes.entidade_cliente AS cliente,
  metabase_changes.grupo_solucionador AS torre,
  metabase_changes.agente_solucionador AS agente_solucao,
  metabase_changes.nome_solicitante AS agente_abertura,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento,
  metabase_changes.tipo_solucao,
  metabase_changes.tags
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
  [[AND {{classificacao_tecnica_drill}}]]
ORDER BY metabase_changes.data_criacao DESC, metabase_changes.chamado DESC;

-- 4) Volume Total de Mudanças - Por Categoria (gráfico)
SELECT
  COALESCE(metabase_changes.categoria, 'Sem categoria') AS categoria,
  COUNT(DISTINCT metabase_changes.chamado) AS total_mudancas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY COALESCE(metabase_changes.categoria, 'Sem categoria')
ORDER BY total_mudancas DESC;

-- 4.1) Drill-down Volume Total de Mudanças - Por Categoria (tabela)
SELECT
  metabase_changes.chamado AS id,
  metabase_changes.titulo_chamado AS titulo,
  COALESCE(metabase_changes.categoria, 'Sem categoria') AS categoria,
  metabase_changes.tipo_atividade AS classificacao_tecnica,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.entidade_cliente AS cliente,
  metabase_changes.grupo_solucionador AS torre,
  metabase_changes.agente_solucionador AS agente_solucao,
  metabase_changes.nome_solicitante AS agente_abertura,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento,
  metabase_changes.tipo_solucao,
  metabase_changes.tags
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
WHERE COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
  [[AND {{categoria_drill}}]]
ORDER BY metabase_changes.data_criacao DESC, metabase_changes.chamado DESC;

-- 5) % de Mudança Executada Com sucesso (gráfico)
SELECT
  DATE_FORMAT(metabase_changes.data_fechamento, '%Y-%m') AS mes,
  ROUND(
    100 *
    (
      COUNT(DISTINCT metabase_changes.chamado)
      - COUNT(DISTINCT CASE
          WHEN dim_tags.name = 'Mudança::Fechado Sem Sucesso' THEN metabase_changes.chamado
        END)
    )
    /
    NULLIF(COUNT(DISTINCT metabase_changes.chamado), 0),
    2
  ) AS percentual_mudanca_sucesso
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
LEFT JOIN (
  SELECT DISTINCT b.change_id
  FROM bridge_change_tags b
  JOIN dim_tags d ON d.tag_id = b.tag_id
  WHERE d.name LIKE 'Mudança::Cancelad%'
) cancelado ON cancelado.change_id = metabase_changes.chamado
WHERE metabase_changes.status_chamado = 'Fechado'
  AND metabase_changes.data_fechamento IS NOT NULL
  AND cancelado.change_id IS NULL
  AND COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY DATE_FORMAT(metabase_changes.data_fechamento, '%Y-%m')
ORDER BY DATE_FORMAT(metabase_changes.data_fechamento, '%Y-%m');

-- 5.1) Drill-down % de Mudança Executada Com sucesso (tabela)
SELECT
  metabase_changes.chamado AS id,
  metabase_changes.titulo_chamado AS titulo,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.categoria,
  metabase_changes.tipo_atividade AS classificacao_tecnica,
  metabase_changes.entidade_cliente AS cliente,
  metabase_changes.grupo_solucionador AS torre,
  metabase_changes.agente_solucionador AS agente_solucao,
  metabase_changes.nome_solicitante AS agente_abertura,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento,
  CASE
    WHEN SUM(CASE WHEN dim_tags.name = 'Mudança::Fechado Sem Sucesso' THEN 1 ELSE 0 END) > 0 THEN 'Sem Sucesso'
    ELSE 'Sucesso'
  END AS resultado_execucao,
  COALESCE(
    NULLIF(
      GROUP_CONCAT(
        DISTINCT CASE
          WHEN dim_tags.name IS NULL OR dim_tags.name = '' THEN NULL
          WHEN dim_tags.name LIKE 'Mudança::Cancelad%' THEN NULL
          ELSE dim_tags.name
        END
        ORDER BY CASE
          WHEN dim_tags.name IS NULL OR dim_tags.name = '' THEN NULL
          WHEN dim_tags.name LIKE 'Mudança::Cancelad%' THEN NULL
          ELSE dim_tags.name
        END
        SEPARATOR ', '
      ),
      ''
    ),
    'Sem etiqueta'
  ) AS etiquetas
FROM metabase_changes
JOIN dim_calendario ON dim_calendario.data = metabase_changes.data_id
LEFT JOIN bridge_change_tags ON bridge_change_tags.change_id = metabase_changes.chamado
LEFT JOIN dim_tags ON dim_tags.tag_id = bridge_change_tags.tag_id
LEFT JOIN (
  SELECT DISTINCT b.change_id
  FROM bridge_change_tags b
  JOIN dim_tags d ON d.tag_id = b.tag_id
  WHERE d.name LIKE 'Mudança::Cancelad%'
) cancelado ON cancelado.change_id = metabase_changes.chamado
WHERE metabase_changes.status_chamado = 'Fechado'
  AND metabase_changes.data_fechamento IS NOT NULL
  AND cancelado.change_id IS NULL
  AND COALESCE(metabase_changes.tipo_solucao, '') NOT IN ('Ticket::Duplicado','Ticket::Cancelado')
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{agente_abertura}}]]
  [[AND {{agente_solucao}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{prioridade}}]]
  [[AND {{etiqueta}}]]
GROUP BY
  metabase_changes.chamado,
  metabase_changes.titulo_chamado,
  metabase_changes.status_chamado,
  metabase_changes.prioridade,
  metabase_changes.categoria,
  metabase_changes.tipo_atividade,
  metabase_changes.entidade_cliente,
  metabase_changes.grupo_solucionador,
  metabase_changes.agente_solucionador,
  metabase_changes.nome_solicitante,
  metabase_changes.data_criacao,
  metabase_changes.data_solucao,
  metabase_changes.data_fechamento
ORDER BY metabase_changes.data_fechamento DESC, metabase_changes.chamado DESC;