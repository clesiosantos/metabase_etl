-- Script de evolução da tabela metabase_timesheet
-- Adiciona IDs originais e formatados para melhor rastreabilidade no Metabase

ALTER TABLE metabase_timesheet
ADD COLUMN id_tarefa_original INT DEFAULT NULL AFTER id_tarefa,
ADD COLUMN id_tarefa_formatado VARCHAR(50) DEFAULT NULL AFTER id_tarefa_original;

-- Índices para performance em filtros
CREATE INDEX idx_timesheet_id_original ON metabase_timesheet(id_tarefa_original);
CREATE INDEX idx_timesheet_id_formatado ON metabase_timesheet(id_tarefa_formatado);