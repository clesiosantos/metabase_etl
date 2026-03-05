/* ============================================================
   RELATÓRIO GESTÃO A VISTA - ABA BACKLOG
   ============================================================ */

-- 1. Volume total de chamados em backlog
SELECT
  COUNT(*) AS total
FROM v_tickets_abertos
WHERE 1=1
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]];

-- 2. Volume de Chamado Por Cliente
SELECT
  entidade_cliente AS cliente,
  COUNT(*) AS total
FROM v_tickets_abertos
WHERE 1=1
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]]
GROUP BY entidade_cliente
ORDER BY total DESC;

-- 3. Volume de Chamado por Status
SELECT
  status_chamado AS status,
  COUNT(*) AS total
FROM v_tickets_abertos
WHERE 1=1
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]]
GROUP BY status_chamado
ORDER BY total DESC;

-- 4. Volume de Chamado por Torre (Grupo de Solução)
SELECT
  grupo_solucao AS torre,
  COUNT(*) AS total
FROM v_tickets_abertos
WHERE 1=1
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]]
GROUP BY grupo_solucao
ORDER BY total DESC;

-- 5. Volume de Chamado por Aging (Faixas de Tempo de Vida)
SELECT
  faixa_aging,
  COUNT(*) AS total
FROM v_tickets_abertos
WHERE 1=1
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]]
GROUP BY faixa_aging
ORDER BY FIELD(faixa_aging, '0 a 3 dias', 'Até 5 dias', 'Até 10 dias', 'Até 15 dias', 'Até 30 dias', 'Maior que 30 dias');

-- 6. Volume de Chamado Dias Sem Atualizar (Faixas de Inatividade)
SELECT
  faixa_sem_atualizacao,
  COUNT(*) AS total
FROM v_tickets_abertos
WHERE 1=1
[[AND {{periodo}}]]
[[AND {{cliente}}]]
[[AND {{grupo}}]]
[[AND {{agente}}]]
[[AND {{prioridade}}]]
[[AND {{status}}]]
[[AND {{canal}}]]
GROUP BY faixa_sem_atualizacao
ORDER BY FIELD(faixa_sem_atualizacao, 'Até 1 dia', 'Até 3 dias', 'Até 7 dias', 'Maior que 7 dias');