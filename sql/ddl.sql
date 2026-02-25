-- DDL para KPIs Gerenciais (Backlog, SLA, Produtividade)

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
  limite_solucao DATETIME NULL,
  limite_atendimento DATETIME NULL,
  sla_risco TINYINT(1) NOT NULL DEFAULT 0,
  sla_atendimento_ok TINYINT(1) NULL,
  sla_solucao_ok TINYINT(1) NULL,
  status_sla VARCHAR(50) NULL,
  tma_minutos DECIMAL(12,2) NULL,
  mttr_minutos DECIMAL(12,2) NULL,
  aging_minutos DECIMAL(12,2) NULL,
  tempo_primeiro_atendimento_minutos DECIMAL(12,2) NULL,
  tempo_espera_minutos DECIMAL(12,2) NULL,
  servico_completo VARCHAR(255) NULL,
  grupo_solucionador VARCHAR(255) NULL,
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
  INDEX idx_tickets_datas (data_criacao, data_fechamento, data_solucao),
  INDEX idx_tickets_status (status_chamado),
  INDEX idx_tickets_entidade (entidade_cliente),
  INDEX idx_tickets_grupo (grupo_solucionador),
  INDEX idx_tickets_tecnico (nome_tecnico_responsavel),
  INDEX idx_tickets_data_carga (data_carga),
  INDEX idx_tickets_aging (aging_minutos),
  INDEX idx_tickets_sla_risco (sla_risco),
  INDEX idx_tickets_sla_ok (sla_atendimento_ok, sla_solucao_ok),
  INDEX idx_tickets_prioridade (prioridade),
  INDEX idx_tickets_tipo (tipo_chamado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS metabase_mudancas (
  mudanca_id INT NOT NULL,
  titulo VARCHAR(255) NULL,
  status VARCHAR(50) NULL,
  prioridade VARCHAR(30) NULL,
  urgencia VARCHAR(30) NULL,
  impacto VARCHAR(30) NULL,
  data_abertura DATETIME NULL,
  data_solucao DATETIME NULL,
  data_fechamento DATETIME NULL,
  previsao_inicio DATETIME NULL,
  previsao_fim DATETIME NULL,
  tipo_mudanca VARCHAR(30) NULL,
  natureza VARCHAR(255) NULL,
  gmud_tipo VARCHAR(255) NULL,
  aprovacao_cab VARCHAR(50) NULL,
  tem_plano TINYINT(1) NOT NULL DEFAULT 0,
  tem_backup TINYINT(1) NOT NULL DEFAULT 0,
  tem_rollback TINYINT(1) NOT NULL DEFAULT 0,
  mudanca_sucesso TINYINT(1) NOT NULL DEFAULT 0,
  grupo_responsavel VARCHAR(255) NULL,
  agente_responsavel VARCHAR(255) NULL,
  entidade_cliente VARCHAR(255) NULL,
  tickets_vinculados INT NOT NULL DEFAULT 0,
  tarefas_total INT NOT NULL DEFAULT 0,
  tarefas_concluidas INT NOT NULL DEFAULT 0,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (mudanca_id),
  INDEX idx_mudancas_datas (data_abertura, data_fechamento, data_solucao),
  INDEX idx_mudancas_status (status),
  INDEX idx_mudancas_entidade (entidade_cliente),
  INDEX idx_mudancas_data_carga (data_carga),
  INDEX idx_mudancas_grupo (grupo_responsavel),
  INDEX idx_mudancas_tecnico (agente_responsavel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS metabase_problemas (
  problema_id INT NOT NULL,
  titulo VARCHAR(255) NULL,
  status VARCHAR(50) NULL,
  prioridade VARCHAR(30) NULL,
  data_abertura DATETIME NULL,
  data_solucao DATETIME NULL,
  data_fechamento DATETIME NULL,
  causas TEXT NULL,
  sintomas TEXT NULL,
  impactos TEXT NULL,
  rca_entregue TINYINT(1) NOT NULL DEFAULT 0,
  rca_no_prazo TINYINT(1) NOT NULL DEFAULT 0,
  pos_mortem TEXT NULL,
  grupo_responsavel VARCHAR(255) NULL,
  agente_responsavel VARCHAR(255) NULL,
  entidade_cliente VARCHAR(255) NULL,
  tickets_vinculados INT NOT NULL DEFAULT 0,
  aprovacao_governanca TINYINT(1) NOT NULL DEFAULT 0,
  aprovacao_sdm TINYINT(1) NOT NULL DEFAULT 0,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (problema_id),
  INDEX idx_problemas_datas (data_abertura, data_fechamento, data_solucao),
  INDEX idx_problemas_status (status),
  INDEX idx_problemas_entidade (entidade_cliente),
  INDEX idx_problemas_data_carga (data_carga),
  INDEX idx_problemas_grupo (grupo_responsavel),
  INDEX idx_problemas_tecnico (agente_responsavel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS metabase_usuarios (
  users_id INT NOT NULL,
  login VARCHAR(100) NULL,
  nome_completo VARCHAR(255) NULL,
  email VARCHAR(255) NULL,
  perfil_padrao VARCHAR(255) NULL,
  grupo_principal VARCHAR(255) NULL,
  entidade_padrao VARCHAR(255) NULL,
  esta_ativo TINYINT(1) NOT NULL DEFAULT 1,
  ultimo_acesso DATETIME NULL,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (users_id),
  INDEX idx_users_login (login),
  INDEX idx_users_email (email),
  INDEX idx_users_ativo (esta_ativo),
  INDEX idx_users_data_carga (data_carga),
  INDEX idx_users_grupo (grupo_principal),
  INDEX idx_users_entidade (entidade_padrao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS metabase_grupos (
  grupo_id INT NOT NULL,
  nome_grupo VARCHAR(255) NULL,
  grupo_pai INT NULL,
  is_assign TINYINT(1) NOT NULL DEFAULT 0,
  is_requester TINYINT(1) NOT NULL DEFAULT 0,
  is_watcher TINYINT(1) NOT NULL DEFAULT 0,
  total_membros INT NOT NULL DEFAULT 0,
  entidade VARCHAR(255) NULL,
  data_carga DATETIME NOT NULL,
  PRIMARY KEY (grupo_id),
  INDEX idx_grupo_pai (grupo_pai),
  INDEX idx_grupos_entidade (entidade),
  INDEX idx_grupos_data_carga (data_carga)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabelas de auditoria
CREATE TABLE IF NOT EXISTS etl_run (
  run_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  status VARCHAR(20) NOT NULL,
  window_full_days INT NOT NULL DEFAULT 15,
  executed_by VARCHAR(100) NULL,
  notes TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS etl_checkpoint (
  entity_name VARCHAR(50) PRIMARY KEY,
  last_success_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS etl_error (
  error_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  run_id BIGINT NOT NULL,
  entity_name VARCHAR(50) NOT NULL,
  error_at DATETIME NOT NULL,
  message TEXT NOT NULL,
  context_json JSON NULL,
  INDEX idx_etl_error_run (run_id),
  INDEX idx_etl_error_entity (entity_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Views para KPIs gerenciais
CREATE OR REPLACE VIEW v_tickets_abertos AS
SELECT * FROM metabase_tickets WHERE status_chamado <> 'Fechado';

CREATE OR REPLACE VIEW v_tickets_sla_risco AS
SELECT * FROM metabase_tickets WHERE sla_risco = 1 OR status_sla = 'SLA FORA DO PRAZO';

CREATE OR REPLACE VIEW v_tickets_aging_alto AS
SELECT * FROM metabase_tickets WHERE aging_minutos > 1440; -- > 24h

CREATE OR REPLACE VIEW v_tickets_sem_interacao AS
SELECT * FROM metabase_tickets WHERE data_ultima_atualizacao < (NOW() - INTERVAL 7 DAY) AND status_chamado <> 'Fechado';

CREATE OR REPLACE VIEW v_produtividade_tecnicos AS
SELECT
  nome_tecnico_responsavel,
  COUNT(*) AS total_chamados,
  SUM(tempo_total_lancados) AS total_horas,
  AVG(mttr_minutos) AS mttr_medio,
  SUM(CASE WHEN sla_solucao_ok = 0 THEN 1 ELSE 0 END) AS sla_estourado
FROM metabase_tickets
WHERE nome_tecnico_responsavel IS NOT NULL
GROUP BY nome_tecnico_responsavel;