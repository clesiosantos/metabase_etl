-- Consulta definitiva para extração do Form 142
SELECT
    CONCAT('FORM_', t.resposta_id) AS id_tarefa,
    t.resposta_id AS id_tarefa_original,
    t.resposta_id AS id_resposta,
    CONCAT(t.ticket_id, '-', t.resposta_id) AS id_tarefa_formatado,
    'Forms' AS tipo_ticket,
    t.ticket_id AS id_pai,
    tk.date AS data_abertura_pai,
    tk.closedate AS data_fechamento_pai,
    
    MAX(CASE WHEN t.id_pergunta = 1653 THEN t.entidade END) AS cliente,
    MAX(CASE WHEN t.id_pergunta = 1654 THEN t.grupo END) AS grupo_solucionador,
    
    COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) AS tecnico,
    
    MAX(CASE WHEN t.id_pergunta = 1651 THEN t.resposta END) AS data_lancamento,
    t.request_date AS data_criacao_tarefa,

    ROUND(TIMESTAMPDIFF(SECOND,
        MAX(CASE WHEN t.id_pergunta = 1651 THEN t.resposta END),
        MAX(CASE WHEN t.id_pergunta = 1652 THEN t.resposta END)
    ) / 3600, 2) AS horas,

    MAX(CASE WHEN t.id_pergunta = 1655 THEN t.resposta END) AS tipo_hora,
    UTC_TIMESTAMP() AS data_carga

FROM (
    SELECT
        fa.id AS resposta_id,
        fa.requester_id,
        fa.request_date,
        it.tickets_id AS ticket_id,
        q.id AS id_pergunta,
        a.answer AS resposta,
        e.name AS entidade,
        g.name AS grupo

    FROM glpi_plugin_formcreator_formanswers fa
    JOIN glpi_plugin_formcreator_answers a ON a.plugin_formcreator_formanswers_id = fa.id
    JOIN glpi_plugin_formcreator_questions q ON q.id = a.plugin_formcreator_questions_id
    LEFT JOIN glpi_items_tickets it ON it.items_id = fa.id AND it.itemtype = 'PluginFormcreatorFormAnswer'
    LEFT JOIN glpi_entities e ON (q.id = 1653 AND e.id = a.answer)
    LEFT JOIN glpi_groups g ON (q.id = 1654 AND g.id = a.answer)
    WHERE fa.id IN (:ids)
      AND q.id IN (1643,1651,1652,1653,1654,1655)
) t
LEFT JOIN glpi_users u ON u.id = t.requester_id
LEFT JOIN glpi_tickets tk ON tk.id = t.ticket_id
GROUP BY t.resposta_id, t.ticket_id, u.id, tk.id, t.request_date;