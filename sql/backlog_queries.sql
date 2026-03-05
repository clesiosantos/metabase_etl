-- 1. Volume Total (Número)
SELECT COUNT(*) AS total
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]] -- Mapear para c.data no Metabase
  [[AND {{cliente}}]]
  [[AND {{grupo}}]]
  [[AND {{agente}}]]
  [[AND {{prioridade}}]]
  [[AND {{status}}]]
  [[AND {{canal}}]];

-- 2. Volume por Cliente (Gráfico de Barras Horizontal)
SELECT 
    t.entidade_cliente, 
    COUNT(*) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
  [[AND {{cliente}}]]
GROUP BY t.entidade_cliente
ORDER BY qtd DESC;

-- 3. Volume por Aging (Gráfico de Barras)
SELECT 
    t.faixa_aging, 
    COUNT(*) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY t.faixa_aging
ORDER BY FIELD(t.faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias');

-- 4. Volume Dias Sem Atualizar (Gráfico de Barras)
SELECT 
    t.faixa_sem_atualizacao, 
    COUNT(*) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  [[AND {{periodo}}]]
GROUP BY t.faixa_sem_atualizacao
ORDER BY FIELD(t.faixa_sem_atualizacao, 'Até 1 dia', 'Até 3 dias', 'Até 7 dias', 'Maior que 7 dias');