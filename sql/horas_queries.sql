-- 1. Visão Geral de Horas (Tabela)
SELECT 
    tecnico AS "Nome do Técnico",
    grupo_solucionador AS "Grupo Solucionador",
    cliente AS "Cliente",
    tipo_ticket AS "Tipo de Ticket",
    tipo_hora AS "Tipo de Hora",
    SUM(horas) AS "Quantidade de Horas",
    COUNT(id_tarefa) AS "Quantidade de Tarefas",
    DATE(data_lancamento) AS "Data do Lançamento"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1, 2, 3, 4, 5, 8
ORDER BY 8 DESC, 1 ASC;

-- 2. Horas por Grupo Solucionador (Gráfico de Barras)
SELECT 
    grupo_solucionador,
    SUM(horas) AS total_horas
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1
ORDER BY 2 DESC;

-- 3. Horas por Cliente (Gráfico de Barras/Ranking)
SELECT 
    cliente,
    SUM(horas) AS total_horas
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1
ORDER BY 2 DESC;

-- 4. Horas por Técnico / Colaborador (Gráfico de Barras)
SELECT 
    tecnico,
    SUM(horas) AS total_horas
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1
ORDER BY 2 DESC;

-- 5. Horas por Técnico / Tipo de Horas (Gráfico Empilhado)
SELECT 
    tecnico,
    tipo_hora,
    SUM(horas) AS total_horas
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1, 2
ORDER BY 1 ASC;

-- 6. Horas por Total (Evolução Mensal)
SELECT 
    DATE_FORMAT(data_lancamento, '%Y-%m-01') AS mes,
    SUM(horas) AS total_horas
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1
ORDER BY 1 ASC;

-- 7. Horas por Total (Por Atividade)
SELECT 
    tipo_ticket AS atividade,
    SUM(horas) AS total_horas
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
GROUP BY 1
ORDER BY 2 DESC;