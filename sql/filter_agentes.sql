-- Consulta para Filtro Unificado de Agentes (Metabase)
-- Consolida nomes de metabase_tickets, metabase_changes, metabase_problems e metabase_timesheet

SELECT DISTINCT agente
FROM (
    SELECT agente_solucionador AS agente 
    FROM metabase_tickets 
    WHERE agente_solucionador IS NOT NULL AND agente_solucionador <> ''

    UNION

    SELECT agente_solucionador AS agente 
    FROM metabase_changes 
    WHERE agente_solucionador IS NOT NULL AND agente_solucionador <> ''

    UNION

    SELECT agente_solucionador AS agente 
    FROM metabase_problems 
    WHERE agente_solucionador IS NOT NULL AND agente_solucionador <> ''

    UNION

    SELECT tecnico AS agente 
    FROM metabase_timesheet 
    WHERE tecnico IS NOT NULL AND tecnico <> ''
) AS consolidado
ORDER BY agente ASC;