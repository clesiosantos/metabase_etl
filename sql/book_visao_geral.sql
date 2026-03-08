-- Filtros:
-- [[AND {{unidade}}]]            -> metabase_tickets.unidade_original
-- [[AND {{categoria}}]]          -> metabase_tickets.categoria_n1
-- [[AND {{urgencia}}]]           -> metabase_tickets.urgencia
-- [[AND {{impacto}}]]            -> metabase_tickets.impacto
-- [[AND {{prioridade}}]]         -> metabase_tickets.prioridade
-- [[AND {{tecnico}}]]            -> metabase_tickets.nome_tecnico_responsavel
-- [[AND {{solicitante}}]]        -> metabase_tickets.nome_solicitante
-- [[AND {{tecnico}}]]            -> metabase_tickets.agente_solucionador
-- [[AND {{status}}]]             -> metabase_tickets.status_chamado

WITH total_tickets AS (
  SELECT count(*) as total
  FROM metabase_tickets
  WHERE 1=1
  [[AND {{unidade}}]]
  [[AND {{categoria}}]]
  [[AND {{urgencia}}]]
  [[AND {{impacto}}]]
  [[AND {{prioridade}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{tecnico}}]]
  [[AND {{status}}]]
),

total_incidentes AS (
  SELECT count(*) as total
  FROM metabase_tickets
  WHERE tipo_chamado = 'Incidente'
  [[AND {{unidade}}]]
  [[AND {{categoria}}]]
  [[AND {{urgencia}}]]
  [[AND {{impacto}}]]
  [[AND {{prioridade}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{tecnico}}]]
  [[AND {{status}}]]
),

total_mudancas AS (
  SELECT count(*) as total
  FROM metabase_changes
  WHERE 1=1
  [[AND {{tecnico}}]]              -- mapear para metabase_changes.agente_solucionador
  [[AND {{solicitante}}]]          -- mapear para metabase_changes.nome_solicitante
),

total_problemas AS (
  SELECT count(*) as total
  FROM metabase_problems
  WHERE 1=1
  [[AND {{tecnico}}]]              -- mapear para metabase_problems.agente_solucionador
  [[AND {{solicitante}}]]          -- mapear para metabase_problems.nome_solicitante
),

sla_cumprido AS (
  SELECT count(*) as total
  FROM metabase_tickets
  WHERE sla_atendido = 'Sim'
  [[AND {{unidade}}]]
  [[AND {{categoria}}]]
  [[AND {{urgencia}}]]
  [[AND {{impacto}}]]
  [[AND {{prioridade}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{tecnico}}]]
  [[AND {{status}}]]
),

first_call_resolution AS (
  SELECT count(*) as total
  FROM metabase_tickets
  WHERE fcr = 'Sim'
  [[AND {{unidade}}]]
  [[AND {{categoria}}]]
  [[AND {{urgencia}}]]
  [[AND {{impacto}}]]
  [[AND {{prioridade}}]]
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{tecnico}}]]
  [[AND {{status}}]]
)

SELECT 
  t.total as tickets_totais,
  i.total as incidentes_totais,
  m.total as mudancas_totais,
  p.total as problemas_totais,
  ROUND((s.total::float / NULLIF(t.total, 0)) * 100, 2) as percentual_sla,
  ROUND((f.total::float / NULLIF(t.total, 0)) * 100, 2) as percentual_fcr
FROM total_tickets t, total_incidentes i, total_mudancas m, total_problemas p, sla_cumprido s, first_call_resolution f