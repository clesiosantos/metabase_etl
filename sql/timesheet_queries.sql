-- Bloco de Filtros Padrão TimeSheet
-- [[AND {{cliente}}]]            -- Mapear para metabase_timesheet.cliente
-- [[AND {{torre}}]]              -- Mapear para metabase_timesheet.grupo_solucionador
-- [[AND {{tecnico}}]]            -- Mapear para metabase_timesheet.tecnico
-- [[AND {{tipo_ticket}}]]        -- Mapear para metabase_timesheet.tipo_ticket
-- [[AND {{periodo_abertura}}]]   -- Mapear para metabase_timesheet.data_abertura_pai
-- [[AND {{periodo_fechamento}}]] -- Mapear para metabase_timesheet.data_fechamento_pai
-- [[AND {{data_lancamento}}]]    -- Mapear para metabase_timesheet.data_lancamento

-- 1. Visão Geral de Horas (Tabela)
SELECT 
    tecnico AS "Nome do Técnico",
    grupo_solucionador AS "Grupo Solucionador",
    cliente AS "Cliente",
    tipo_ticket AS "Tipo de Ticket",
    tipo_hora AS "Tipo de Hora",
    SUM(horas) AS "Quantidade de Horas",
    COUNT(id_tarefa) AS "Quantidade de Tarefas",
    data_lancamento AS "Data do Lançamento"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY tecnico, grupo_solucionador, cliente, tipo_ticket, tipo_hora, data_lancamento
ORDER BY data_lancamento DESC;

-- 2. Horas por Grupo Solucionador (Gráfico)
SELECT 
    grupo_solucionador AS "Grupo",
    SUM(horas) AS "Total Horas"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY grupo_solucionador
ORDER BY "Total Horas" DESC;

-- 3. Horas por Cliente (Gráfico)
SELECT 
    cliente AS "Cliente",
    SUM(horas) AS "Total Horas"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY cliente
ORDER BY "Total Horas" DESC;

-- 4. Horas por Técnico / Colaborador (Gráfico)
SELECT 
    tecnico AS "Técnico",
    SUM(horas) AS "Total Horas"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY tecnico
ORDER BY "Total Horas" DESC;

-- 5. Horas por Técnico / Tipo de Horas (Gráfico)
-- Visão comparativa entre Comercial, Plantão e Outros
SELECT 
    tecnico AS "Técnico",
    tipo_hora AS "Tipo de Hora",
    SUM(horas) AS "Total Horas"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY tecnico, tipo_hora
ORDER BY tecnico, tipo_hora;

-- 6. Horas por Total (Mensal)
SELECT 
    DATE_FORMAT(data_lancamento, '%Y-%m') AS "Mês",
    SUM(horas) AS "Total Horas"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY 1
ORDER BY 1;

-- 7. Horas por Total (Consolidado por Tipo de Atividade)
-- Atividade aqui refere-se ao Tipo de Ticket ou Categoria da Tarefa
SELECT 
    tipo_ticket AS "Atividade",
    SUM(horas) AS "Total Horas"
FROM metabase_timesheet
WHERE 1=1
  [[AND {{cliente}}]]
  [[AND {{torre}}]]
  [[AND {{tecnico}}]]
  [[AND {{tipo_ticket}}]]
  [[AND {{periodo_abertura}}]]
  [[AND {{periodo_fechamento}}]]
  [[AND {{data_lancamento}}]]
GROUP BY tipo_ticket
ORDER BY "Total Horas" DESC;