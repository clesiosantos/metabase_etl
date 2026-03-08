-- Tabela consolidada para relatórios de TimeSheet (Horas de Tarefas)
CREATE TABLE IF NOT EXISTS metabase_timesheet (
    id_tarefa VARCHAR(50) NOT NULL, -- Ex: 'Ticket_123', 'Change_45'
    tipo_ticket VARCHAR(20) NOT NULL, -- 'Ticket', 'Change', 'Problem'
    id_pai INT NOT NULL, -- ID do Chamado/Mudança/Problema
    data_abertura_pai DATETIME NULL,
    data_fechamento_pai DATETIME NULL,
    cliente VARCHAR(255) NULL,
    grupo_solucionador VARCHAR(255) NULL,
    tecnico VARCHAR(255) NULL,
    data_lancamento DATETIME NULL,
    horas DECIMAL(10,4) DEFAULT 0,
    tipo_hora VARCHAR(50) NULL, -- 'Comercial', 'Plantão'
    data_carga DATETIME NOT NULL,
    PRIMARY KEY (id_tarefa),
    INDEX idx_ts_tecnico (tecnico),
    INDEX idx_ts_cliente (cliente),
    INDEX idx_ts_data (data_lancamento),
    INDEX idx_ts_grupo (grupo_solucionador)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;