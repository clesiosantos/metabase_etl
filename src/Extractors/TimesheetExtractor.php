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

      $table = 'glpi_' . strtolower($type) . 'tasks';
      $parentTable = 'glpi_' . strtolower($type) . 's';
      
      $groupTable = 'glpi_groups_tickets'; 
      if ($type === 'Change') $groupTable = 'glpi_changes_groups';
      if ($type === 'Problem') $groupTable = 'glpi_groups_problems';
      
      $fk = strtolower($type) . 's_id';
      $placeholders = implode(',', array_fill(0, count($ids), '?'));

      $queries[] = "
        SELECT
          CONCAT('$type', '_', tk.id) as id_tarefa,
          tk.id as id_tarefa_original,
          NULL as id_resposta,
          CONCAT(p.id, '-', tk.id) as id_tarefa_formatado,
          '$type' as tipo_ticket,
          p.id as id_pai,
          p.date as data_abertura_pai,
          p.closedate as data_fechamento_pai,
          e.name as cliente,
          COALESCE(gd.area_atuacao, 'Sem grupo') as grupo_solucionador,
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) as tecnico,
          tk.date as data_lancamento,
          tk.date as data_criacao_tarefa,
          (tk.actiontime / 3600) as horas,
          COALESCE(tc.name, 'Comercial') as tipo_hora,
          UTC_TIMESTAMP() as data_carga
        FROM $table tk
        JOIN $parentTable p ON p.id = tk.$fk
        LEFT JOIN glpi_entities e ON e.id = p.entities_id
        LEFT JOIN glpi_users u ON u.id = tk.users_id
        LEFT JOIN glpi_taskcategories tc ON tc.id = tk.taskcategories_id
        LEFT JOIN (
            SELECT
                $fk,
                MIN(g.name) AS area_atuacao
            FROM $groupTable gt
            INNER JOIN glpi_groups g ON g.id = gt.groups_id
            WHERE gt.type = 2
            GROUP BY $fk
        ) gd ON gd.$fk = p.id
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

  public static function fetchChangedForm142Ids(PDO $src, string $lastUtc): array {
    $sql = "
      SELECT fa.id
      FROM glpi_plugin_formcreator_formanswers fa
      WHERE fa.plugin_formcreator_forms_id = 142 
        AND fa.request_date >= ?
    ";
    $st = $src->prepare($sql);
    $st->execute([$lastUtc]);
    return array_map('intval', $st->fetchAll(PDO::FETCH_COLUMN));
  }

  public static function fetchForm142Details(PDO $src, array $ids): PDOStatement {
    $placeholders = implode(',', array_fill(0, count($ids), '?'));

    $sql = "
      SELECT 
          CONCAT('FORM_', fa.id) AS id_tarefa,
          fa.id AS id_tarefa_original,
          fa.id AS id_resposta,
          CONCAT(tk.id, '-') AS id_tarefa_formatado,
          'Forms' AS tipo_ticket,
          tk.id AS id_pai,
          tk.date AS data_abertura_pai,
          tk.closedate AS data_fechamento_pai,
          
          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1653 THEN ent.name END) AS cliente,
          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1654 THEN grp.name END) AS grupo_solucionador,
          
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) AS tecnico,
          
          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1651 THEN ans.answer END) AS data_lancamento,
          fa.request_date AS data_criacao_tarefa,

          ROUND(TIMESTAMPDIFF(SECOND, 
              MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1651 THEN ans.answer END), 
              MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1652 THEN ans.answer END)
          ) / 3600, 2) AS horas,

          MAX(CASE WHEN ans.plugin_formcreator_questions_id = 1655 THEN ans.answer END) AS tipo_hora,
          UTC_TIMESTAMP() AS data_carga

      FROM glpi_plugin_formcreator_formanswers fa
      JOIN glpi_tickets tk ON tk.id = fa.items_id AND fa.itemtype = 'Ticket'
      JOIN glpi_users u ON u.id = fa.requester_id
      JOIN glpi_plugin_formcreator_answers ans ON ans.plugin_formcreator_formanswers_id = fa.id
      
      LEFT JOIN glpi_entities ent ON (ans.plugin_formcreator_questions_id = 1653 AND ent.id = ans.answer)
      LEFT JOIN glpi_groups grp ON (ans.plugin_formcreator_questions_id = 1654 AND grp.id = ans.answer)
      
      WHERE fa.id IN ($placeholders)
      GROUP BY fa.id
    ";

    $st = $src->prepare($sql);
    $st->execute($ids);
    return $st;
  }
}