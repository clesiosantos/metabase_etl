-- Criação das tabelas históricas para monitoramento de backlog no DW (Metabase)
-- Uma tabela para Incidentes e Requisições (Tickets) e outra para Problemas.

-- 1. Tabela Histórica de Backlog de Tickets (Incidentes e Requisições)
CREATE TABLE IF NOT EXISTS history_tickets_backlog (
    chamado_id INT,
    data_abertura DATETIME,
    data_coleta DATE,
    PRIMARY KEY (chamado_id, data_coleta),
    INDEX idx_data_coleta (data_coleta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tabela Histórica de Backlog de Problemas
CREATE TABLE IF NOT EXISTS history_problems_backlog (
    problem_id INT,
    data_abertura DATETIME,
    data_coleta DATE,
    PRIMARY KEY (problem_id, data_coleta),
    INDEX idx_data_coleta (data_coleta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
