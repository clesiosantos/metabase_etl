-- Criação do Banco de Dados
CREATE DATABASE IF NOT EXISTS dw_glpi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE dw_glpi;

-- Tabela de Controle de Checkpoint
CREATE TABLE IF NOT EXISTS etl_checkpoint (
    entity_name VARCHAR(50) PRIMARY KEY,
    last_success_at DATETIME NOT NULL
) ENGINE=InnoDB;

-- Tabela de Log de Execuções
CREATE TABLE IF NOT EXISTS etl_run (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    started_at DATETIME NOT NULL,
    finished_at DATETIME DEFAULT NULL,
    status ENUM('RUNNING', 'SUCCESS', 'FAILED') NOT NULL,
    mode ENUM('incremental', 'full') NOT NULL,
    entity_name VARCHAR(50) NOT NULL,
    window_full_days INT DEFAULT 0,
    batch_size INT DEFAULT 1000,
    ids_selected INT DEFAULT 0,
    rows_upserted INT DEFAULT 0,
    tables_updated TEXT,
    validation_json JSON,
    message TEXT
) ENGINE=InnoDB;

-- Tabela de Log de Erros
CREATE TABLE IF NOT EXISTS etl_error (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    run_id INT,
    error_at DATETIME NOT NULL,
    entity_name VARCHAR(50),
    message TEXT,
    context_json JSON,
    INDEX (run_id)
) ENGINE=InnoDB;

-- Dimensão de Tags
CREATE TABLE IF NOT EXISTS dim_tags (
    tag_id INT PRIMARY KEY,
    entities_id INT,
    is_recursive TINYINT(1),
    is_active TINYINT(1),
    name VARCHAR(255),
    comment TEXT,
    color VARCHAR(20),
    type_menu INT,
    data_carga DATETIME
) ENGINE=InnoDB;

-- Ponte Ticket x Tags
CREATE TABLE IF NOT EXISTS bridge_ticket_tags (
    ticket_id INT,
    tag_id INT,
    data_carga DATETIME,
    PRIMARY KEY (ticket_id, tag_id),
    INDEX (tag_id)
) ENGINE=InnoDB;

-- Tabela Fato: Tickets (Metabase)
CREATE TABLE IF NOT EXISTS metabase_tickets (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255),
    tipo_chamado VARCHAR(50),
    data_criacao DATETIME,
    data_solucao DATETIME,
    data_fechamento DATETIME,
    data_ultima_atualizacao DATETIME,
    data_id DATE,
    status_chamado VARCHAR(50),
    prioridade VARCHAR(10),
    urgencia VARCHAR(10),
    impacto VARCHAR(10),
    canal VARCHAR(100),
    status_sla VARCHAR(50),
    tto_status VARCHAR(50),
    ttr_status VARCHAR(50),
    tto_em_risco TINYINT(1) DEFAULT 0,
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME,
    limite_atendimento DATETIME,
    sla_risco TINYINT(1) DEFAULT 0,
    sla_atendimento_ok TINYINT(1),
    sla_solucao_ok TINYINT(1),
    tma_minutos FLOAT,
    mttr_minutos FLOAT,
    aging_minutos FLOAT,
    tempo_primeiro_atendimento_minutos FLOAT,
    tempo_espera_minutos FLOAT,
    dias_sem_atualizacao INT,
    faixa_sem_atualizacao VARCHAR(50),
    faixa_aging VARCHAR(50),
    servico_completo VARCHAR(255),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    servico VARCHAR(100),
    tipo_solucao VARCHAR(255),
    disciplina_solucao VARCHAR(255),
    modelo_solucao VARCHAR(255),
    grupo_solucionador VARCHAR(255),
    grupo_solucionador_nome VARCHAR(255),
    id_grupo_solucionador INT,
    tipo_contrato VARCHAR(100),
    grupo_solucao VARCHAR(100),
    tipo_atividade VARCHAR(100),
    agente_solucionador VARCHAR(255),
    nome_solicitante VARCHAR(255),
    nome_tecnico_responsavel VARCHAR(255),
    entidade_cliente VARCHAR(255),
    localizacao_fisica VARCHAR(255),
    reaberturas INT DEFAULT 0,
    tempo_total_lancados FLOAT,
    tem_tecnico_atribuido TINYINT(1) DEFAULT 0,
    tem_prioridade TINYINT(1) DEFAULT 0,
    incidente_recorrente TINYINT(1) DEFAULT 0,
    tags TEXT,
    users_id_recipient INT,
    locations_id INT,
    data_carga DATETIME,
    INDEX (data_id),
    INDEX (status_chamado),
    INDEX (entidade_cliente)
) ENGINE=InnoDB;

-- Tabela Fato: Mudanças (Metabase)
CREATE TABLE IF NOT EXISTS metabase_changes (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255),
    data_criacao DATETIME,
    data_solucao DATETIME,
    data_fechamento DATETIME,
    data_ultima_atualizacao DATETIME,
    data_id DATE,
    status_chamado VARCHAR(50),
    prioridade VARCHAR(10),
    urgencia VARCHAR(10),
    impacto VARCHAR(10),
    ttr_status VARCHAR(50),
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME,
    mttr_minutos FLOAT,
    aging_minutos FLOAT,
    servico_completo VARCHAR(255),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    servico VARCHAR(100),
    tipo_solucao VARCHAR(255),
    disciplina_solucao VARCHAR(255),
    modelo_solucao VARCHAR(255),
    grupo_solucionador VARCHAR(255),
    grupo_solucionador_nome VARCHAR(255),
    id_grupo_solucionador INT,
    tipo_contrato VARCHAR(100),
    grupo_solucao VARCHAR(100),
    tipo_atividade VARCHAR(100),
    agente_solucionador VARCHAR(255),
    nome_solicitante VARCHAR(255),
    entidade_cliente VARCHAR(255),
    localizacao_fisica VARCHAR(255),
    tags TEXT,
    users_id_recipient INT,
    locations_id INT,
    data_carga DATETIME,
    INDEX (data_id)
) ENGINE=InnoDB;

-- Tabela Fato: Problemas (Metabase)
CREATE TABLE IF NOT EXISTS metabase_problems (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255),
    data_criacao DATETIME,
    data_solucao DATETIME,
    data_fechamento DATETIME,
    data_ultima_atualizacao DATETIME,
    data_id DATE,
    status_chamado VARCHAR(50),
    prioridade VARCHAR(10),
    urgencia VARCHAR(10),
    impacto VARCHAR(10),
    ttr_status VARCHAR(50),
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME,
    mttr_minutos FLOAT,
    aging_minutos FLOAT,
    servico_completo VARCHAR(255),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    servico VARCHAR(100),
    tipo_solucao VARCHAR(255),
    disciplina_solucao VARCHAR(255),
    modelo_solucao VARCHAR(255),
    grupo_solucionador VARCHAR(255),
    grupo_solucionador_nome VARCHAR(255),
    id_grupo_solucionador INT,
    tipo_contrato VARCHAR(100),
    grupo_solucao VARCHAR(100),
    tipo_atividade VARCHAR(100),
    agente_solucionador VARCHAR(255),
    nome_solicitante VARCHAR(255),
    entidade_cliente VARCHAR(255),
    localizacao_fisica VARCHAR(255),
    tags TEXT,
    users_id_recipient INT,
    locations_id INT,
    data_carga DATETIME,
    INDEX (data_id)
) ENGINE=InnoDB;