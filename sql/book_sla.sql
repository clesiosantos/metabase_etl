SELECT
    count(case when s.situacao_sla = 'Dentro do SLA' then 1 end) as dentro_sla,
    count(case when s.situacao_sla = 'SLA Excedido' then 1 end) as fora_sla,
    count(case when s.situacao_sla = 'SLA em Andamento' then 1 end) as em_andamento
FROM
    v_sla_solicitacoes s
WHERE
    1=1
    [[AND {{periodo}}]]
    [[AND {{tecnico}}]]
    [[AND {{solicitante}}]]
    [[AND {{tecnico}}]]
    [[AND {{status}}]]

SELECT
    s.tecnico,
    count(case when s.situacao_sla = 'Dentro do SLA' then 1 end) as dentro_sla,
    count(case when s.situacao_sla = 'SLA Excedido' then 1 end) as fora_sla
FROM
    v_sla_solicitacoes s
WHERE
    1=1
    [[AND {{periodo}}]]
    [[AND {{tecnico}}]]
    [[AND {{solicitante}}]]
    [[AND {{tecnico}}]]
    [[AND {{status}}]]
GROUP BY
    s.tecnico
ORDER BY
    fora_sla DESC