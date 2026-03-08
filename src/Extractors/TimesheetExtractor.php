<?php
declare(strict_types=1);

final class TimesheetExtractor {
  public static function fetchChangedTaskIds(PDO $src, string $lastUtc): array {
    // Usamos '?' para evitar erro de parâmetros nomeados duplicados em UNION
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
          '$type' as tipo_ticket,
          p.id as id_pai,
          p.date as data_abertura_pai,
          p.closedate as data_fechamento_pai,
          e.name as cliente,
          COALESCE(g.name, 'Sem Grupo') as grupo_solucionador,
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) as tecnico,
          tk.begin as data_lancamento,
          (tk.actiontime / 3600) as horas,
          CASE 
            WHEN WEEKDAY(tk.begin) < 5 AND HOUR(tk.begin) BETWEEN 8 AND 17 THEN 'Comercial'
            ELSE 'Plantão'
          END as tipo_hora,
          UTC_TIMESTAMP() as data_carga
        FROM glpi_$table tk
        JOIN $parentTable p ON p.id = tk.$fk
        LEFT JOIN glpi_entities e ON e.id = p.entities_id
        LEFT JOIN glpi_users u ON u.id = tk.users_id
        LEFT JOIN (
          SELECT users_id, MIN(groups_id) as groups_id 
          FROM glpi_groups_users 
          GROUP BY users_id
        ) gu ON gu.users_id = u.id
        LEFT JOIN glpi_groups g ON g.id = gu.groups_id
        WHERE tk.id IN ($placeholders)
      ";
      
      foreach ($ids as $id) $params[] = $id;
    }

    if (empty($queries)) {
        // Retorna um statement vazio se não houver IDs
        return $src->query("SELECT 1 FROM (SELECT 1) AS t WHERE 1=0");
    }

    $fullSql = implode(" UNION ALL ", $queries);
    $st = $src->prepare($fullSql);
    $st->execute($params);
    return $st;
  }
}