-- Adiciona campos do Plugin Fields (Gestão de Mudanças) na tabela do DW
ALTER TABLE metabase_changes
  ADD COLUMN classificacao VARCHAR(255) NULL AFTER tipo_atividade,
  ADD COLUMN classificacao_tecnica VARCHAR(255) NULL AFTER classificacao,
  ADD COLUMN ambiente VARCHAR(255) NULL AFTER classificacao_tecnica,
  ADD COLUMN data_inicio_mudanca DATETIME NULL AFTER ambiente,
  ADD COLUMN data_fim_mudanca DATETIME NULL AFTER data_inicio_mudanca,
  ADD COLUMN justificativa TEXT NULL AFTER data_fim_mudanca,
  ADD COLUMN impacto_negocio TEXT NULL AFTER justificativa;
