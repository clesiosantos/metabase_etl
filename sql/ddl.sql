CREATE DATABASE IF NOT EXISTS dw_glpi
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE dw_glpi;

CREATE TABLE IF NOT EXISTS etl_checkpoint (
  entity_name VARCHAR(50) PRIMARY KEY,
  last_success_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS metabase_tickets (
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
  tma_minutos DECIMAL(12,2) NULL,
  mttr_minutos DECIMAL(12,2) NULL,
  aging_minutos DECIMAL(12,2) NULL,
  tempo_primeiro_atendimento_minutos DECIMAL(12,2) NULL,
  tempo_espera_minutos DECIMAL(12,2) NULL,
  
  /* Colunas de Catálogo */
  servico_completo VARCHAR(255) NULL,
  categoria VARCHAR(255) NULL,
  subcategoria VARCHAR(255) NULL,
  servico VARCHAR(255) NULL,
  
  /* Colunas de Grupo Solucionador */
  grupo_solucionador VARCHAR(255) NULL,
  id_grupo_solucionador INT NULL,
  tipo_atividade VARCHAR(255) NULL,
  tipo_contrato VARCHAR(255) NULL,
  grupo_solucao VARCHAR(255) NULL,
  
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
  INDEX idx_tickets_tecnico (nome_tecnico_responsavel),
  INDEX idx_tickets_dates (data_criacao, data_fechamento, data_solucao),
  INDEX idx_tickets_sla (status_sla, sla_risco, limite_solucao),
  INDEX idx_tickets_aging (aging_minutos),
  INDEX idx_tickets_data_carga (data_carga)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;