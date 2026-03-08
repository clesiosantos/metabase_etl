/* REQUISICOES_DATA_TABLE */
SELECT 
    r.id,
    r.assunto,
    r.data_abertura,
    r.status,
    u.nome as solicitante,
    a.nome as tecnico
FROM requisicoes r
LEFT JOIN usuarios u ON r.solicitante_id = u.id
LEFT JOIN usuarios a ON r.agente_solucao_id = a.id
WHERE 1=1
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{tecnico}}]]
  [[AND {{status}}]]

/* REQUISICOES_COUNT */
SELECT 
    count(*) as total
FROM requisicoes r
WHERE 1=1
  [[AND {{tecnico}}]]
  [[AND {{solicitante}}]]
  [[AND {{tecnico}}]]
  [[AND {{status}}]]