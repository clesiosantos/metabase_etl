<?php
declare(strict_types=1);

final class TimesheetExtractor {
  public static function fetchChangedTaskIds(PDO $src, string $lastUtc): array {
    $sql = "
      SELECT 'Ticket' as type, id FROM glpi_tickettasks WHERE date_mod >= ?
      UNION ALL
      SELECT 'Change' as type, id FROM glpi_changetasks WHERE date_mod >= ?
      UNION ALL
      SELECT 'Problem' as type, id FROM glpi_problemtasks WHERE date_mod >= ?
    ";
    $st = $src->prepare($sql);
    $st->execute([$lastUtc, $lastUtc, $lastUtc]);
    return $st->fetchAll(PDO::FETCH_ASSOC);
  }

  public static function fetchTaskDetails(PDO $src, array $tasks): PDOStatement {
    $queries = [];
    $params = [];

    foreach (['Ticket', 'Change', 'Problem'] as $type) {
      $ids = array_column(array_filter($tasks, fn($t) => $t['type'] === $type), 'id');
      if (!$ids) continue;

      $table = strtolower($type) . 'tasks';
      $parentTable = 'glpi_' . strtolower($type) . 's';
      $fk = strtolower($type) . 's_id';
      $placeholders = implode(',', array_fill(0, count($ids), '?'));

      $queries[] = "
        SELECT
          CONCAT('$type', '_', tk.id) as id_tarefa,
          tk.id as id_tarefa_original,
          CONCAT(p.id, '-', tk.id) as id_tarefa_formatado,
          '$type' as tipo_ticket,
          p.id as id_pai,
          p.date as data_abertura_pai,
          p.closedate as data_fechamento_pai,
          e.name as cliente,
          COALESCE(g.name, 'Sem Grupo') as grupo_solucionador,
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) as tecnico,
          tk.begin as data_lancamento,
          tk.date as data_criacao_tarefa,
          (tk.actiontime / 3600) as horas,
          COALESCE(tc.name, 'Comercial') as tipo_hora,
          UTC_TIMESTAMP() as data_carga
        FROM glpi_$table tk
        JOIN $parentTable p ON p.id = tk.$fk
        LEFT JOIN glpi_entities e ON e.id = p.entities_id
        LEFT JOIN glpi_users u ON u.id = tk.users_id
        LEFT JOIN glpi_taskcategories tc ON tc.id = tk.taskcategories_id
        LEFT JOIN (
          SELECT users_id, MIN(groups_id) as groups_id 
          FROM gu_groups_users 
          GROUP BY users_id
        ) gu ON gu.users_id = u.id
        LEFT JOIN glpi_groups g ON g.id = gu.groups_id
        WHERE tk.id IN ($placeholders)
      ";
      
      foreach ($ids as $id) $params[] = $id;
    }

    if (empty($queries)) {
        return $src->query("SELECT 1 FROM (SELECT 1) AS t WHERE 1=0");
    }

    $fullSql = implode(" UNION ALL ", $queries);
    $st = $src->prepare($fullSql);
    $st->execute($params);
    return $st;
  }

  /**
   * Busca IDs de respostas do Formcreator 142 alteradas
   */
  public static function fetchChangedForm142Ids(PDO $src, string $lastUtc): array {
    $sql = "
      SELECT fa.id
      FROM glpi_plugin_formcreator_formanswers fa
      JOIN glpi_plugin_formcreator_forms f ON f.id = fa.plugin_formcreator_forms_id
      WHERE f.id = 142 
        AND fa.date_mod >= ?
    ";
    $st = $src->prepare($sql);
    $st->execute([$lastUtc]);
    return array_map('intval', $st->fetchAll(PDO::FETCH_COLUMN));
  }

  /**
   * Extrai detalhes pivotados do Formcreator 142
   */
  public static function fetchForm142Details(PDO $src, array $ids): PDOStatement {
    $placeholders = implode(',', array_fill(0, count($ids), '?'));

    $sql = "
      SELECT 
          CONCAT('FORM_', fa.id) AS id_tarefa,
          fa.id AS id_tarefa_original,
          CONCAT(tk.id, '-', COALESCE(tt.id, '')) AS id_tarefa_formatado,
          'Ticket' AS tipo_ticket,
          tk.id AS id_pai,
          tk.date AS data_abertura_pai,
          tk.closedate AS data_fechamento_pai,
          
          -- Pivoteamento das perguntas específicas
          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1653 THEN ent.name END) AS cliente,
          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1654 THEN grp.name END) AS grupo_solucionador,
          
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) AS tecnico,
          
          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1651 THEN ans.answer END) AS data_lancamento,
          fa.date_mod AS data_criacao_tarefa,

          ROUND(TIMESTAMPDIFF(SECOND, 
              MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1651 THEN ans.answer END), 
              MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1652 THEN ans.answer END)
          ) / 3600, 2) AS horas,

          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1655 THEN ans.answer END) AS tipo_hora,
          UTC_TIMESTAMP() AS data_carga

      FROM glpi_plugin_formcreator_formanswers fa
      JOIN glpi_plugin_formcreator_formanswers_issues fai ON fai.plugin_formcreator_formanswers_id = fa.id
      JOIN glpi_tickets tk ON tk.id = fai.items_id AND fai.itemtype = 'Ticket'
      JOIN glpi_users u ON u.id = fa.users_id
      JOIN glpi_plugin_formcreator_answers ans ON ans.plugin_formcreator_formanswers_id = fa.id
      
      -- Joins auxiliares para pegar nomes de entidades/grupos das respostas
      LEFT JOIN glpi_entities ent ON (ans.plugin_formcreator_questions_id = 1653 AND ent.id = ans.answer)
      LEFT JOIN glpi_groups grp ON (ans.plugin_formcreator_questions_id = 1654 AND grp.id = ans.answer)
      
      -- Tenta encontrar uma tarefa real vinculada (opcional)
      LEFT JOIN glpi_tickettasks tt ON tt.tickets_id = tk.id AND tt.date_mod >= fa.date_creation

      WHERE fa.id IN ($placeholders)
      GROUP BY fa.id
    ";

    $st = $src->prepare($sql);
    $st->execute($ids);
    return $st;
  }
}