-- Bloco de Filtros Padrão (Copiar para todas as perguntas no Metabase)
-- [[AND {{periodo_abertura}}]] -- Mapear para dim_calendario.data
-- [[AND {{cliente}}]]           -- Mapear para metabase_tickets.entidade_cliente
-- [[AND {{torre}}]]             -- Mapear para metabase_tickets.grupo_solucao
-- [[AND {{tecnico}}]]           -- Mapear para metabase_tickets.nome_tecnico_responsavel
-- [[AND {{solicitante}}]]       -- Mapear para metabase_tickets.nome_solicitante
-- [[AND {{status}}]]            -- Mapear para metabase_tickets.status_chamado
-- [[AND {{tipo_solucao}}]]      -- Mapear para metabase_tickets.tipo_solucao
-- [[AND {{tipo_chamado}}]]      -- Mapear para metabase_tickets.tipo_chamado
-- [[AND {{prioridade}}]]        -- Mapear para metabase_tickets.prioridade

-- 1. Volume Total (Número)
SELECT COUNT(*) AS total
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]];

-- 2. Volume por Cliente (Gráfico de Barras Horizontal)
SELECT 
    metabase_tickets.entidade_cliente, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
GROUP BY metabase_tickets.entidade_cliente
ORDER BY qtd DESC;

-- 3. Volume por Torre (Gráfico de Barras)
SELECT 
    metabase_tickets.grupo_solucao, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
GROUP BY metabase_tickets.grupo_solucao
ORDER BY qtd DESC;

-- 4. Volume por Aging (Gráfico de Barras)
SELECT 
    metabase_tickets.faixa_aging, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
GROUP BY metabase_tickets.faixa_aging
ORDER BY FIELD(metabase_tickets.faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias');

-- 5. Volume Dias Sem Atualizar (Gráfico de Barras)
SELECT 
    metabase_tickets.faixa_sem_atualizacao, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
GROUP BY metabase_tickets.faixa_sem_atualizacao
ORDER BY FIELD(metabase_tickets.faixa_sem_atualizacao, 'Até 1 dia', 'Até 3 dias', 'Até 7 dias', 'Maior que 7 dias');

-- 6. Volume por Status (Gráfico de Pizza ou Barras)
SELECT 
    metabase_tickets.status_chamado, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo_abertura}}]]
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{status}}]]
  [[AND {{tipo_solucao}}]]
  [[AND {{tipo_chamado}}]]
  [[AND {{prioridade}}]]
GROUP BY metabase_tickets.status_chamado
ORDER BY qtd DESC;