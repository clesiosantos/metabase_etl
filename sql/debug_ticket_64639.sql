-- Execute este comando no banco de dados do GLPI (Origem)
-- Objetivo: Validar se os campos 'begin' e 'date' estão preenchidos na origem

SELECT
    tk.id AS id_tarefa_glpi,
    p.id AS id_ticket,
    tk.begin AS data_inicio_real, -- Mapeado para data_lancamento
    tk.date AS data_registro,     -- Mapeado para data_criacao_tarefa
    tk.actiontime AS tempo_segundos,
    u.name AS tecnico_login,
    tc.name AS categoria_tarefa
FROM glpi_tickettasks tk
JOIN glpi_tickets p ON p.id = tk.tickets_id
LEFT JOIN glpi_users u ON u.id = tk.users_id
LEFT JOIN glpi_taskcategories tc ON tc.id = tk.taskcategories_id
WHERE p.id = 64639;