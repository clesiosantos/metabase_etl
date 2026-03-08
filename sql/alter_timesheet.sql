-- Comando para garantir a existência e o tipo da coluna data_lancamento
ALTER TABLE metabase_timesheet 
MODIFY COLUMN data_lancamento DATETIME AFTER tecnico;

-- Caso a coluna não exista, utilize o comando abaixo (comentado):
-- ALTER TABLE metabase_timesheet ADD COLUMN data_lancamento DATETIME AFTER tecnico;

-- Adiciona índice para performance se não existir
CREATE INDEX IF NOT EXISTS idx_data_lancamento ON metabase_timesheet (data_lancamento);