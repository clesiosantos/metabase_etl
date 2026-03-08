-- 1. Tabelas de Controle do ETL
CREATE TABLE IF NOT EXISTS etl_checkpoint (
    entity_name VARCHAR(50) NOT NULL,
    last_success_at DATETIME NOT NULL,
    PRIMARY KEY (entity_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS etl_run (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    started_at DATETIME NOT NULL,
    finished_at DATETIME NULL,
    status ENUM('RUNNING', 'SUCCESS', 'FAILED') NOT NULL,
    mode ENUM('incremental', 'full') NOT NULL,
    entity_name VARCHAR(50) NOT NULL,
    ids_selected INT DEFAULT 0,
    rows_upserted INT DEFAULT 0,
    window_full_days INT DEFAULT 0,
    batch_size INT DEFAULT 0,
    tables_updated TEXT NULL,
    validation_json JSON NULL,
    message TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS etl_error (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    run_id INT NULL,
    error_at DATETIME NOT NULL,
    entity_name VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    context_json JSON NULL,
    INDEX idx_error_run (run_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Dimensões e Tabelas Auxiliares
CREATE TABLE IF NOT EXISTS dim_tags (
    tag_id INT PRIMARY KEY,
    entities_id INT NULL,
    is_recursive TINYINT(1) DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    name VARCHAR(255) NOT NULL,
    comment TEXT NULL,
    color VARCHAR(20) NULL,
    type_menu INT DEFAULT 0,
    data_carga DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Tabelas de Fato / Metabase (Tickets)
CREATE TABLE IF NOT EXISTS metabase_tickets (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255) NULL,
    tipo_chamado VARCHAR(50) NULL,
    data_criacao DATETIME NULL,
    data_solucao DATETIME NULL,
    data_fechamento DATETIME NULL,
    data_ultima_atualizacao DATETIME NULL,
    data_id DATE NULL,
    status_chamado VARCHAR(50) NULL,
    prioridade VARCHAR(20) NULL,
    urgencia VARCHAR(20) NULL,
    impacto VARCHAR(20) NULL,
    canal VARCHAR(100) NULL,
    status_sla VARCHAR(50) NULL,
    tto_status VARCHAR(50) NULL,
    ttr_status VARCHAR(50) NULL,
    tto_em_risco TINYINT(1) DEFAULT 0,
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME NULL,
    limite_atendimento DATETIME NULL,
    sla_risco TINYINT(1) DEFAULT 0,
    sla_atendimento_ok TINYINT(1) NULL,
    sla_solucao_ok TINYINT(1) NULL,
    tma_minutos INT NULL,
    mttr_minutos INT NULL,
    aging_minutos INT NULL,
    tempo_primeiro_atendimento_minutos INT NULL,
    tempo_espera_minutos INT NULL,
    dias_sem_atualizacao INT NULL,
    faixa_sem_atualizacao VARCHAR(50) NULL,
    faixa_aging VARCHAR(50) NULL,
    servico_completo VARCHAR(255) NULL,
    categoria VARCHAR(100) NULL,
    subcategoria VARCHAR(100) NULL,
    servico VARCHAR(100) NULL,
    tipo_solucao VARCHAR(255) NULL,
    disciplina_solucao VARCHAR(100) NULL,
    modelo_solucao VARCHAR(100) NULL,
    grupo_solucionador VARCHAR(255) NULL,
    grupo_solucionador_nome VARCHAR(255) NULL,
    id_grupo_solucionador INT NULL,
    tipo_contrato VARCHAR(100) NULL,
    grupo_solucao VARCHAR(100) NULL,
    tipo_atividade VARCHAR(100) NULL,
    agente_solucionador VARCHAR(255) NULL,
    nome_solicitante VARCHAR(255) NULL,
    nome_tecnico_responsavel VARCHAR(255) NULL,
    entidade_cliente VARCHAR(255) NULL,
    localizacao_fisica VARCHAR(255) NULL,
    reaberturas INT DEFAULT 0,
    tempo_total_lancados DECIMAL(10,4) DEFAULT 0,
    tem_tecnico_atribuido TINYINT(1) DEFAULT 0,
    tem_prioridade TINYINT(1) DEFAULT 0,
    incidente_recorrente TINYINT(1) DEFAULT 0,
    tags TEXT NULL,
    users_id_recipient INT NULL,
    locations_id INT NULL,
    data_carga DATETIME NOT NULL,
    INDEX idx_tickets_data (data_id),
    INDEX idx_tickets_status (status_chamado),
    INDEX idx_tickets_cliente (entidade_cliente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ponte para Tags (Muitos para Muitos)
CREATE TABLE IF NOT EXISTS bridge_ticket_tags (
    ticket_id INT NOT NULL,
    tag_id INT NOT NULL,
    data_carga DATETIME NOT NULL,
    PRIMARY KEY (ticket_id, tag_id),
    INDEX idx_bridge_tag (tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Tabelas de Mudanças e Problemas
CREATE TABLE IF NOT EXISTS metabase_changes (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255) NULL,
    data_criacao DATETIME NULL,
    data_solucao DATETIME NULL,
    data_fechamento DATETIME NULL,
    data_ultima_atualizacao DATETIME NULL,
    data_id DATE NULL,
    status_chamado VARCHAR(50) NULL,
    prioridade VARCHAR(20) NULL,
    urgencia VARCHAR(20) NULL,
    impacto VARCHAR(20) NULL,
    ttr_status VARCHAR(50) NULL,
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME NULL,
    mttr_minutos INT NULL,
    aging_minutos INT NULL,
    servico_completo VARCHAR(255) NULL,
    categoria VARCHAR(100) NULL,
    subcategoria VARCHAR(100) NULL,
    servico VARCHAR(100) NULL,
    tipo_solucao VARCHAR(255) NULL,
    disciplina_solucao VARCHAR(100) NULL,
    modelo_solucao VARCHAR(100) NULL,
    grupo_solucionador VARCHAR(255) NULL,
    grupo_solucionador_nome VARCHAR(255) NULL,
    id_grupo_solucionador INT NULL,
    tipo_contrato VARCHAR(100) NULL,
    grupo_solucao VARCHAR(100) NULL,
    tipo_atividade VARCHAR(100) NULL,
    agente_solucionador VARCHAR(255) NULL,
    nome_solicitante VARCHAR(255) NULL,
    entidade_cliente VARCHAR(255) NULL,
    localizacao_fisica VARCHAR(255) NULL,
    tags TEXT NULL,
    users_id_recipient INT NULL,
    locations_id INT NULL,
    data_carga DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS metabase_problems (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255) NULL,
    data_criacao DATETIME NULL,
    data_solucao DATETIME NULL,
    data_fechamento DATETIME NULL,
    data_ultima_atualizacao DATETIME NULL,
    data_id DATE NULL,
    status_chamado VARCHAR(50) NULL,
    prioridade VARCHAR(20) NULL,
    urgencia VARCHAR(20) NULL,
    impacto VARCHAR(20) NULL,
    ttr_status VARCHAR(50) NULL,
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME NULL,
    mttr_minutos INT NULL,
    aging_minutos INT NULL,
    servico_completo VARCHAR(255) NULL,
    categoria VARCHAR(100) NULL,
    subcategoria VARCHAR(100) NULL,
    servico VARCHAR(100) NULL,
    tipo_solucao VARCHAR(255) NULL,
    disciplina_solucao VARCHAR(100) NULL,
    modelo_solucao VARCHAR(100) NULL,
    grupo_solucionador VARCHAR(255) NULL,
    grupo_solucionador_nome VARCHAR(255) NULL,
    id_grupo_solucionador INT NULL,
    tipo_contrato VARCHAR(100) NULL,
    grupo_solucao VARCHAR(100) NULL,
    tipo_atividade VARCHAR(100) NULL,
    agente_solucionador VARCHAR(255) NULL,
    nome_solicitante VARCHAR(255) NULL,
    entidade_cliente VARCHAR(255) NULL,
    localizacao_fisica VARCHAR(255) NULL,
    tags TEXT NULL,
    users_id_recipient INT NULL,
    locations_id INT NULL,
    data_carga DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Tabela de TimeSheet (Consolidada)
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;