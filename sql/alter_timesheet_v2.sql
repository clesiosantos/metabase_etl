-- Script de evolução da tabela metabase_timesheet
-- Adiciona IDs originais, formatados e a data de criação original da tarefa

ALTER TABLE metabase_timesheet
ADD COLUMN id_tarefa_original INT DEFAULT NULL AFTER id_tarefa,
ADD COLUMN id_tarefa_formatado VARCHAR(50) DEFAULT NULL AFTER id_tarefa_original,
ADD COLUMN data_criacao_tarefa DATETIME DEFAULT NULL AFTER data_lancamento;

-- Índices para performance em filtros
CREATE INDEX idx_timesheet_id_original ON metabase_timesheet(id_tarefa_original);
CREATE INDEX idx_timesheet_id_formatado ON metabase_timesheet(id_tarefa_formatado);
CREATE INDEX idx_timesheet_data_criacao ON metabase_timesheet(data_criacao_tarefa);