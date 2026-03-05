-- 1. Volume Total (Número)
SELECT COUNT(*) AS total
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
  [[AND {{grupo}}]]
  [[AND {{agente}}]]
  [[AND {{prioridade}}]]
  [[AND {{status}}]]
  [[AND {{canal}}]];

-- 2. Volume por Cliente (Gráfico de Barras Horizontal)
SELECT 
    metabase_tickets.entidade_cliente, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY metabase_tickets.entidade_cliente
ORDER BY qtd DESC;

-- 3. Volume por Aging (Gráfico de Barras)
SELECT 
    metabase_tickets.faixa_aging, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY metabase_tickets.faixa_aging
ORDER BY FIELD(metabase_tickets.faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias');

-- 4. Volume Dias Sem Atualizar (Gráfico de Barras)
SELECT 
    metabase_tickets.faixa_sem_atualizacao, 
    COUNT(*) AS qtd
FROM metabase_tickets
JOIN dim_calendario ON dim_calendario.data = metabase_tickets.data_id
WHERE metabase_tickets.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY metabase_tickets.faixa_sem_atualizacao
ORDER BY FIELD(metabase_tickets.faixa_sem_atualizacao, 'Até 1 dia', 'Até 3 dias', 'Até 7 dias', 'Maior que 7 dias');