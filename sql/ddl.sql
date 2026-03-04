/* ============================================================
   DW GLPI - DDL COMPLETO (AJUSTADO PARA TTO/TTR E FAIXAS DE ATUALIZAÇÃO)
   ============================================================ */

CREATE DATABASE IF NOT EXISTS dw_glpi
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE dw_glpi;

DROP VIEW IF EXISTS v_tickets_ultimos_15_dias;
DROP VIEW IF EXISTS v_tickets_sla_risco;
DROP VIEW IF EXISTS v_tickets_abertos;

DROP TABLE IF EXISTS bridge_ticket_tags;
DROP TABLE IF EXISTS dim_tags;
DROP TABLE IF EXISTS metabase_tickets;
DROP TABLE IF EXISTS metabase_changes;
DROP TABLE IF EXISTS metabase_problems;
DROP TABLE IF EXISTS dim_calendario;
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

CREATE TABLE dim_calendario (
  data DATE NOT NULL,
  ano INT NOT NULL,
  mes INT NOT NULL,
  dia INT NOT NULL,
  trimestre INT NOT NULL,
  semana_do_ano INT NOT NULL,
  dia_da_semana_num INT NOT NULL,
  dia_da_semana_nome VARCHAR(20) NOT NULL,
  mes_nome VARCHAR(20) NOT NULL,
  ano_mes VARCHAR(7) NOT NULL,
  eh_fim_de_semana TINYINT(1) NOT NULL,
  PRIMARY KEY (data),
  INDEX idx_cal_ano_mes (ano, mes),
  INDEX idx_cal_ano_trimestre (ano, trimestre),
  INDEX idx_cal_ano_semana (ano, semana_do_ano)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE dim_tags (
  tag_id INT UNSIGNED NOT NULL,
  entities_id INT UNSIGNED NOT NULL,
  is_recursive TINYINT NOT NULL,
  is_active TINYINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  comment TEXT NULL,
  color VARCHAR(50) NOT NULL,
  type_menu TEXT NULL,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (tag_id),
  INDEX idx_dim_tags_active (is_active),
  INDEX idx_dim_tags_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bridge_ticket_tags (
  ticket_id INT NOT NULL,
  tag_id INT UNSIGNED NOT NULL,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (ticket_id, tag_id),
  INDEX idx_bridge_tag (tag_id),
  INDEX idx_bridge_ticket (ticket_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE metabase_tickets (
  chamado INT NOT NULL,
  titulo_chamado VARCHAR(255) NULL,
  tipo_chamado VARCHAR(50) NULL,
  data_criacao DATETIME NULL,
  data_solucao DATETIME NULL,
  data_fechamento DATETIME NULL,
  data_ultima_atualizacao DATETIME NULL,
  data_id DATE NULL,
  status_chamado VARCHAR(30) NULL,
  prioridade VARCHAR(30) NULL,
  urgencia VARCHAR(30) NULL,
  impacto VARCHAR(30) NULL,
  status_sla VARCHAR(50) NULL,
  tto_status VARCHAR(20) NULL,
  ttr_status VARCHAR(20) NULL,
  tto_em_risco TINYINT(1) NOT NULL DEFAULT 0,
  ttr_em_risco TINYINT(1) NOT NULL DEFAULT 0,
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
  
  /* Colunas de Atualização */
  dias_sem_atualizacao INT NULL,
  faixa_sem_atualizacao VARCHAR(50) NULL,

  servico_completo VARCHAR(255) NULL,
  categoria VARCHAR(255) NULL,
  subcategoria VARCHAR(255) NULL,
  servico VARCHAR(255) NULL,
  grupo_solucionador VARCHAR(255) NULL,
  grupo_solucionador_nome VARCHAR(255) NULL,
  id_grupo_solucionador INT NULL,
  tipo_contrato VARCHAR(255) NULL,
  grupo_solucao VARCHAR(255) NULL,
  tipo_atividade VARCHAR(255) NULL,
  agente_solucionador VARCHAR(255) NULL,
  nome_solicitante VARCHAR(255) NULL,
  nome_tecnico_responsavel VARCHAR(255) NULL,
  entidade_cliente VARCHAR(255) NULL,
  localizacao_fisica VARCHAR(255) NULL,
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
  INDEX idx_tickets_data_id (data_id),
  INDEX idx_tickets_faixa_upd (faixa_sem_atualizacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE metabase_changes (
  chamado INT NOT NULL,
  titulo_chamado VARCHAR(255) NULL,
  data_criacao DATETIME NULL,
  data_solucao DATETIME NULL,
  data_fechamento DATETIME NULL,
  data_ultima_atualizacao DATETIME NULL,
  data_id DATE NULL,
  status_chamado VARCHAR(30) NULL,
  prioridade VARCHAR(30) NULL,
  urgencia VARCHAR(30) NULL,
  impacto VARCHAR(30) NULL,
  ttr_status VARCHAR(50) NULL,
  ttr_em_risco TINYINT(1) NOT NULL DEFAULT 0,
  limite_solucao DATETIME NULL,
  mttr_minutos DECIMAL(12,2) NULL,
  aging_minutos DECIMAL(12,2) NULL,
  
  /* Colunas de Atualização */
  dias_sem_atualizacao INT NULL,
  faixa_sem_atualizacao VARCHAR(50) NULL,

  servico_completo VARCHAR(255) NULL,
  categoria VARCHAR(255) NULL,
  subcategoria VARCHAR(255) NULL,
  servico VARCHAR(255) NULL,
  grupo_solucionador VARCHAR(255) NULL,
  grupo_solucionador_nome VARCHAR(255) NULL,
  id_grupo_solucionador INT NULL,
  tipo_contrato VARCHAR(255) NULL,
  grupo_solucao VARCHAR(255) NULL,
  tipo_atividade VARCHAR(255) NULL,
  agente_solucionador VARCHAR(255) NULL,
  nome_solicitante VARCHAR(255) NULL,
  entidade_cliente VARCHAR(255) NULL,
  localizacao_fisica VARCHAR(255) NULL,
  tags VARCHAR(1000) NULL,
  users_id_recipient INT NULL,
  locations_id INT NULL,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (chamado),
  INDEX idx_changes_status (status_chamado),
  INDEX idx_changes_data_id (data_id),
  INDEX idx_changes_faixa_upd (faixa_sem_atualizacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE metabase_problems (
  chamado INT NOT NULL,
  titulo_chamado VARCHAR(255) NULL,
  data_criacao DATETIME NULL,
  data_solucao DATETIME NULL,
  data_fechamento DATETIME NULL,
  data_ultima_atualizacao DATETIME NULL,
  data_id DATE NULL,
  status_chamado VARCHAR(30) NULL,
  prioridade VARCHAR(30) NULL,
  urgencia VARCHAR(30) NULL,
  impacto VARCHAR(30) NULL,
  ttr_status VARCHAR(50) NULL,
  ttr_em_risco TINYINT(1) NOT NULL DEFAULT 0,
  limite_solucao DATETIME NULL,
  mttr_minutos DECIMAL(12,2) NULL,
  aging_minutos DECIMAL(12,2) NULL,
  
  /* Colunas de Atualização */
  dias_sem_atualizacao INT NULL,
  faixa_sem_atualizacao VARCHAR(50) NULL,

  servico_completo VARCHAR(255) NULL,
  categoria VARCHAR(255) NULL,
  subcategoria VARCHAR(255) NULL,
  servico VARCHAR(255) NULL,
  grupo_solucionador VARCHAR(255) NULL,
  grupo_solucionador_nome VARCHAR(255) NULL,
  id_grupo_solucionador INT NULL,
  tipo_contrato VARCHAR(255) NULL,
  grupo_solucao VARCHAR(255) NULL,
  tipo_atividade VARCHAR(255) NULL,
  agente_solucionador VARCHAR(255) NULL,
  nome_solicitante VARCHAR(255) NULL,
  entidade_cliente VARCHAR(255) NULL,
  localizacao_fisica VARCHAR(255) NULL,
  tags VARCHAR(1000) NULL,
  users_id_recipient INT NULL,
  locations_id INT NULL,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (chamado),
  INDEX idx_problems_status (status_chamado),
  INDEX idx_problems_data_id (data_id),
  INDEX idx_problems_faixa_upd (faixa_sem_atualizacao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE VIEW v_tickets_abertos AS
SELECT * FROM metabase_tickets WHERE status_chamado <> 'Fechado';

CREATE VIEW v_tickets_sla_risco AS
SELECT * FROM metabase_tickets WHERE sla_risco = 1 OR status_sla = 'SLA FORA DO PRAZO' OR tto_em_risco = 1 OR ttr_em_risco = 1;

CREATE VIEW v_tickets_ultimos_15_dias AS
SELECT * FROM metabase_tickets WHERE data_criacao >= (UTC_TIMESTAMP() - INTERVAL 15 DAY);