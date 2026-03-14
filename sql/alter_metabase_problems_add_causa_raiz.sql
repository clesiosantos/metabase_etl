-- Adiciona campo de Causa Raiz (Plugin Fields - Gestão de Problemas) na tabela do DW
ALTER TABLE metabase_problems
  ADD COLUMN causa_raiz VARCHAR(255) NULL AFTER tipo_atividade;
