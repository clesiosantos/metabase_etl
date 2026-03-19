-- Consulta para Filtro Unificado de Agentes (Metabase)
-- Resolvido: Illegal mix of collations (Error 1271)

SELECT DISTINCT agente
FROM (
    SELECT agente_solucionador COLLATE utf8mb4_unicode_ci AS agente 
    FROM metabase_tickets 
    WHERE agente_solucionador IS NOT NULL AND agente_solucionador <> ''

    UNION

    SELECT agente_solucionador COLLATE utf8mb4_unicode_ci AS agente 
    FROM metabase_changes 
    WHERE agente_solucionador IS NOT NULL AND agente_solucionador <> ''

    UNION

    SELECT agente_solucionador COLLATE utf8mb4_unicode_ci AS agente 
    FROM metabase_problems 
    WHERE agente_solucionador IS NOT NULL AND agente_solucionador <> ''

    UNION

    SELECT tecnico COLLATE utf8mb4_unicode_ci AS agente 
    FROM metabase_timesheet 
    WHERE tecnico IS NOT NULL AND tecnico <> ''
) AS consolidado
ORDER BY agente ASC;