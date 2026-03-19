SELECT 
    CONCAT('FORM_', fa.id) AS id_tarefa,
    fa.id AS id_tarefa_original,
    fa.id AS id_resposta,
    CONCAT(tk.id, '-') AS id_tarefa_formatado,
    'Forms' AS tipo_ticket,
    tk.id AS id_pai,
    tk.date AS data_abertura_pai,
    tk.closedate AS data_fechamento_pai,
    
    MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1653 THEN ent.name END) AS cliente,
    MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1654 THEN grp.name END) AS grupo_solucionador,
    
    COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) AS tecnico,
    
    MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1651 THEN ans.answer END) AS data_lancamento,
    fa.date_creation AS data_criacao_tarefa,

    ROUND(TIMESTAMPDIFF(SECOND, 
        MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1651 THEN ans.answer END), 
        MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1652 THEN ans.answer END)
    ) / 3600, 2) AS horas,

    MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1655 THEN ans.answer END) AS tipo_hora,
    UTC_TIMESTAMP() AS data_carga

FROM glpi_plugin_formcreator_formanswers fa
JOIN glpi_tickets tk ON tk.id = fa.items_id AND fa.itemtype = 'Ticket'
JOIN glpi_users u ON u.id = fa.users_id
JOIN glpi_plugin_formcreator_answers ans ON ans.plugin_formcreator_formanswers_id = fa.id

LEFT JOIN glpi_entities ent ON (ans.plugin_formcreator_questions_id = 1653 AND ent.id = ans.answer)
LEFT JOIN glpi_groups grp ON (ans.plugin_formcreator_questions_id = 1654 AND grp.id = ans.answer)

WHERE fa.id IN ($placeholders)
GROUP BY fa.id