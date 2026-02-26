CREATE DATABASE IF NOT EXISTS dw_glpi
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE dw_glpi;

DROP VIEW IF EXISTS v_tickets_ultimos_15_dias;
DROP VIEW IF EXISTS v_tickets_sla_risco;
DROP VIEW IF EXISTS v_tickets_abertos;

DROP TABLE IF EXISTS metabase_tickets;
DROP TABLE IF EXISTS etl_error;
DROP TABLE IF EXISTS etl_run;
DROP TABLE IF EXISTS etl_checkpoint;

CREATE TABLE etl_run (
  run_id BIGINT NOT NULL AUTO_INCREMENT,
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  status VARCHAR(20) NOT NULL,
  mode VARCHAR(20) NOT NULL,
  entity_name VARCHAR(50) NOT NULL,
  window_full_days INT NOT NULL DEFAULT 15,
  batch_size INT NOT NULL DEFAULT 1000,
  tables_updated VARCHAR(500) NULL,
  ids_selected INT NOT NULL DEFAULT 0,
  rows_upserted INT NOT NULL DEFAULT 0,
  validation_json JSON NULL,
  message TEXT NULL,
  PRIMARY KEY (run_id),
  INDEX idx_etl_run_entity (entity_name, started_at),
  INDEX idx_etl_run_status (status, started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE etl_error (
  error_id BIGINT NOT NULL AUTO_INCREMENT,
  run_id BIGINT NULL,
  error_at DATETIME NOT NULL,
  entity_name VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  context_json JSON NULL,
  PRIMARY KEY (error_id),
  INDEX idx_etl_error_run (run_id),
  INDEX idx_etl_error_entity (entity_name, error_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE etl_checkpoint (
  entity_name VARCHAR(50) NOT NULL,
  last_success_at DATETIME NOT NULL,
  PRIMARY KEY (entity_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE metabase_tickets (
  chamado INT NOT NULL,

  titulo_chamado VARCHAR(255) NULL,
  tipo_chamado VARCHAR(50) NULL,

  data_criacao DATETIME NULL,
  data_solucao DATETIME NULL,
  data_fechamento DATETIME NULL,
  data_ultima_atualizacao DATETIME NULL,

  status_chamado VARCHAR(30) NULL,

  prioridade VARCHAR(30) NULL,
  urgencia VARCHAR(30) NULL,
  impacto VARCHAR(30) NULL,

  status_sla VARCHAR(50) NULL,
  limite_solucao DATETIME NULL,
  limite_atendimento DATETIME NULL,
  sla_risco TINYINT(1) NOT NULL DEFAULT 0,
  sla_atendimento_ok TINYINT(1) NULL,
  sla_solucao_ok TINYINT(1) NULL,

  tempo_primeiro_atendimento_minutos DECIMAL(12,2) NULL,
  tma_minutos DECIMAL(12,2) NULL,
  mttr_minutos DECIMAL(12,2) NULL,
  aging_minutos DECIMAL(12,2) NULL,
  tempo_espera_minutos DECIMAL(12,2) NULL,

  servico_completo VARCHAR(255) NULL,
  categoria VARCHAR(255) NULL,
  subcategoria VARCHAR(255) NULL,
  servico VARCHAR(255) NULL,

  /* Grupo: completename (principal no Metabase) + name (curto) */
  grupo_solucionador VARCHAR(255) NULL,         /* gsol.completename */
  grupo_solucionador_nome VARCHAR(255) NULL,    /* gsol.name */
  id_grupo_solucionador INT NULL,

  /* Quebra do completename */
  tipo_contrato VARCHAR(255) NULL,
  grupo_solucao VARCHAR(255) NULL,
  tipo_atividade VARCHAR(255) NULL,

  agente_solucionador VARCHAR(255) NULL,
  nome_solicitante VARCHAR(255) NULL,
  nome_tecnico_responsavel VARCHAR(255) NULL,

  entidade_cliente VARCHAR(255) NULL,
  localizacao_fisica VARCHAR(255) NULL,

  periodo_avaliado VARCHAR(20) NULL,
  periodo VARCHAR(20) NULL,

  reaberturas INT NOT NULL DEFAULT 0,
  tempo_total_lancados DECIMAL(12,2) NULL,
  tem_tecnico_atribuido TINYINT(1) NOT NULL DEFAULT 0,
  tem_prioridade TINYINT(1) NOT NULL DEFAULT 0,
  incidente_recorrente TINYINT(1) NOT NULL DEFAULT 0,

  tags VARCHAR(1000) NULL,

  users_id_recipient INT NULL,
  locations_id INT NULL,

  data_carga DATETIME NOT NULL,

  PRIMARY KEY (chamado),

  INDEX idx_tickets_status (status_chamado),
  INDEX idx_tickets_cliente (entidade_cliente),

  INDEX idx_tickets_grupo (grupo_solucionador),
  INDEX idx_tickets_grupo_nome (grupo_solucionador_nome),
  INDEX idx_tickets_grupo_id (id_grupo_solucionador),

  INDEX idx_tickets_tecnico (nome_tecnico_responsavel),
  INDEX idx_tickets_datas (data_criacao, data_solucao, data_fechamento),
  INDEX idx_tickets_date_mod (data_ultima_atualizacao),

  INDEX idx_tickets_sla (status_sla, sla_risco, limite_solucao),
  INDEX idx_tickets_aging (aging_minutos),

  INDEX idx_tickets_catalogo (categoria, subcategoria, servico),
  INDEX idx_tickets_data_carga (data_carga)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE VIEW v_tickets_abertos AS
SELECT *
FROM metabase_tickets
WHERE status_chamado <> 'Fechado';

CREATE VIEW v_tickets_sla_risco AS
SELECT *
FROM metabase_tickets
WHERE sla_risco = 1
   OR status_sla = 'SLA FORA DO PRAZO';

CREATE VIEW v_tickets_ultimos_15_dias AS
SELECT *
FROM metabase_tickets
WHERE data_criacao >= (UTC_TIMESTAMP() - INTERVAL 15 DAY);