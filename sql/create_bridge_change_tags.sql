-- Cria a ponte de tags para Mudanças no DW (caso ainda não exista)
CREATE TABLE IF NOT EXISTS bridge_change_tags (
  change_id INT,
  tag_id INT,
  data_carga DATETIME,
  PRIMARY KEY (change_id, tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
