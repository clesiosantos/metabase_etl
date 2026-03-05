/* ============================================================
   RELATÓRIO GESTÃO A VISTA - ABA BACKLOG
   ============================================================ */

-- 1. Volume Total (Número)
SELECT
  COUNT(t.chamado) AS total_backlog
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  AND t.servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]];

-- 2. Volume por Cliente
SELECT
  t.entidade_cliente,
  COUNT(t.chamado) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  AND t.servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
[[AND {{periodo}}]]
[[AND {{cliente}}]]
GROUP BY t.entidade_cliente
ORDER BY qtd DESC;

-- 3. Volume por Status
SELECT
  t.status_chamado,
  COUNT(t.chamado) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  AND t.servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
[[AND {{periodo}}]]
[[AND {{status}}]]
GROUP BY t.status_chamado
ORDER BY qtd DESC;

-- 4. Volume por Aging (Faixa de Tempo de Vida)
SELECT
  t.faixa_aging,
  COUNT(t.chamado) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  AND t.servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
[[AND {{periodo}}]]
GROUP BY t.faixa_aging
ORDER BY FIELD(t.faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias');

-- 5. Volume Dias Sem Atualizar
SELECT
  t.faixa_sem_atualizacao,
  COUNT(t.chamado) AS qtd
FROM metabase_tickets t
JOIN dim_calendario c ON c.data = t.data_id
WHERE t.status_chamado NOT IN ('Solucionado', 'Fechado')
  AND t.servico NOT IN ('Ticket::Duplicado', 'Ticket::Cancelado')
[[AND {{periodo}}]]
GROUP BY t.faixa_sem_atualizacao
ORDER BY FIELD(t.faixa_sem_atualizacao, 'Até 1 dia', 'Até 3 dias', 'Até 7 dias', 'Maior que 7 dias');