-- Tabela de Tickets (Principal)
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
    prioridade VARCHAR(20),
    urgencia VARCHAR(20),
    impacto VARCHAR(20),
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
    tma_minutos INT,
    mttr_minutos INT,
    aging_minutos INT,
    tempo_primeiro_atendimento_minutos INT,
    tempo_espera_minutos INT,
    dias_sem_atualizacao INT,
    faixa_sem_atualizacao VARCHAR(50),
    faixa_aging VARCHAR(50),
    servico_completo VARCHAR(255),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    servico VARCHAR(100),
    tipo_solucao VARCHAR(255),
    disciplina_solucao VARCHAR(100),
    modelo_solucao VARCHAR(100),
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
    tempo_total_lancados DECIMAL(10,2),
    tem_tecnico_atribuido TINYINT(1),
    tem_prioridade TINYINT(1),
    incidente_recorrente TINYINT(1) DEFAULT 0,
    tags TEXT,
    users_id_recipient INT,
    locations_id INT,
    data_carga DATETIME,
    INDEX idx_data_id (data_id),
    INDEX idx_status (status_chamado),
    INDEX idx_entidade (entidade_cliente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Mudanças
CREATE TABLE IF NOT EXISTS metabase_changes (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255),
    data_criacao DATETIME,
    data_solucao DATETIME,
    data_fechamento DATETIME,
    data_ultima_atualizacao DATETIME,
    data_id DATE,
    status_chamado VARCHAR(50),
    prioridade VARCHAR(20),
    urgencia VARCHAR(20),
    impacto VARCHAR(20),
    ttr_status VARCHAR(50),
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME,
    mttr_minutos INT,
    aging_minutos INT,
    servico_completo VARCHAR(255),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    servico VARCHAR(100),
    tipo_solucao VARCHAR(255),
    disciplina_solucao VARCHAR(100),
    modelo_solucao VARCHAR(100),
    grupo_solucionador VARCHAR(255),
    grupo_solucionador_nome VARCHAR(255),
    id_grupo_solucionador INT,
    tipo_contrato VARCHAR(100),
    grupo_solucao VARCHAR(100),
    tipo_atividade VARCHAR(100),

    classificacao VARCHAR(255),
    classificacao_tecnica VARCHAR(255),
    ambiente VARCHAR(255),
    data_inicio_mudanca DATETIME,
    data_fim_mudanca DATETIME,
    justificativa TEXT,
    impacto_negocio TEXT,

    agente_solucionador VARCHAR(255),
    nome_solicitante VARCHAR(255),
    entidade_cliente VARCHAR(255),
    localizacao_fisica VARCHAR(255),
    tags TEXT,
    users_id_recipient INT,
    locations_id INT,
    data_carga DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Problemas
CREATE TABLE IF NOT EXISTS metabase_problems (
    chamado INT PRIMARY KEY,
    titulo_chamado VARCHAR(255),
    data_criacao DATETIME,
    data_solucao DATETIME,
    data_fechamento DATETIME,
    data_ultima_atualizacao DATETIME,
    data_id DATE,
    status_chamado VARCHAR(50),
    prioridade VARCHAR(20),
    urgencia VARCHAR(20),
    impacto VARCHAR(20),
    ttr_status VARCHAR(50),
    ttr_em_risco TINYINT(1) DEFAULT 0,
    limite_solucao DATETIME,
    mttr_minutos INT,
    aging_minutos INT,
    servico_completo VARCHAR(255),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    servico VARCHAR(100),
    tipo_solucao VARCHAR(255),
    disciplina_solucao VARCHAR(100),
    modelo_solucao VARCHAR(100),
    grupo_solucionador VARCHAR(255),
    grupo_solucionador_nome VARCHAR(255),
    id_grupo_solucionador INT,
    tipo_contrato VARCHAR(100),
    grupo_solucao VARCHAR(100),
    tipo_atividade VARCHAR(100),
    causa_raiz VARCHAR(255),
    agente_solucionador VARCHAR(255),
    nome_solicitante VARCHAR(255),
    entidade_cliente VARCHAR(255),
    localizacao_fisica VARCHAR(255),
    tags TEXT,
    users_id_recipient INT,
    locations_id INT,
    data_carga DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Timesheet Consolidado
CREATE TABLE IF NOT EXISTS metabase_timesheet (
    id_tarefa VARCHAR(100) PRIMARY KEY,
    tipo_ticket VARCHAR(20),
    id_pai INT,
    data_abertura_pai DATETIME,
    data_fechamento_pai DATETIME,
    cliente VARCHAR(255),
    grupo_solucionador VARCHAR(255),
    tecnico VARCHAR(255),
    data_lancamento DATETIME,
    horas DECIMAL(10,4),
    tipo_hora VARCHAR(50),
    data_carga DATETIME,
    INDEX idx_data_lancamento (data_lancamento),
    INDEX idx_tecnico (tecnico),
    INDEX idx_cliente (cliente)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabelas de Controle e Dimensões
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bridge_ticket_tags (
    ticket_id INT,
    tag_id INT,
    data_carga DATETIME,
    PRIMARY KEY (ticket_id, tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bridge_change_tags (
    change_id INT,
    tag_id INT,
    data_carga DATETIME,
    PRIMARY KEY (change_id, tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bridge_problem_tags (
    problem_id INT,
    tag_id INT,
    data_carga DATETIME,
    PRIMARY KEY (problem_id, tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS etl_checkpoint (
    entity_name VARCHAR(50) PRIMARY KEY,
    last_success_at DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS etl_run (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    started_at DATETIME,
    finished_at DATETIME,
    status VARCHAR(20),
    mode VARCHAR(20),
    entity_name VARCHAR(50),
    window_full_days INT,
    batch_size INT,
    ids_selected INT DEFAULT 0,
    rows_upserted INT DEFAULT 0,
    tables_updated TEXT,
    validation_json JSON,
    message TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS etl_error (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    run_id INT,
    error_at DATETIME,
    entity_name VARCHAR(50),
    message TEXT,
    context_json JSON
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;