-- 1. Primeiro, vamos ver o que tem na tarefa padrão para o ticket 64639
SELECT 
    id, 
    tickets_id, 
    `date` AS data_criacao_padrao, 
    `begin` AS data_inicio_padrao, 
    actiontime 
FROM glpi_tickettasks 
WHERE tickets_id = 64639;

-- 2. Agora, vamos procurar se existem tabelas de 'Plugin Fields' vinculadas às tarefas.
-- Execute este comando para listar tabelas que podem conter os dados do seu "formulário"
SHOW TABLES LIKE 'glpi_plugin_fields_tickettask%';

-- 3. Se você souber o nome da tabela do formulário (ex: glpi_plugin_fields_tickettasktimesheets), 
-- tente rodar o join abaixo (ajuste o nome da tabela 'f' se for diferente):
/*
SELECT 
    tk.id AS tarefa_id,
    tk.tickets_id,
    f.* -- Aqui veremos todos os campos do seu formulário
FROM glpi_tickettasks tk
LEFT JOIN glpi_plugin_fields_tickettaskXXXXXXXXs f ON f.items_id = tk.id
WHERE tk.tickets_id = 64639;
*/