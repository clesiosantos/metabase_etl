<?php
declare(strict_types=1);

final class TimesheetExtractor {
  public static function fetchChangedTaskIds(PDO $src, string $lastUtc): array {
    // Busca IDs de tarefas modificadas recentemente em todas as frentes
    $sql = "
      SELECT 'Ticket' as type, id FROM glpi_tickettasks WHERE date_mod >= :last
      UNION ALL
      SELECT 'Change' as type, id FROM glpi_changetasks WHERE date_mod >= :last
      UNION ALL
      SELECT 'Problem' as type, id FROM glpi_problemtasks WHERE date_mod >= :last
    ";
    $st = $src->prepare($sql);
    $st->execute([':last' => $lastUtc]);
    return $st->fetchAll(PDO::FETCH_ASSOC);
  }

  public static function fetchTaskDetails(PDO $src, array $tasks): PDOStatement {
    // Como as tarefas vêm de tabelas diferentes, usamos UNION para unificar a extração
    // Para performance, filtramos pelos IDs específicos passados
    
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
          
          -- Grupo Solucionador (Lógica simplificada baseada no técnico da tarefa)
          COALESCE(g.name, 'Sem Grupo') as grupo_solucionador,
          
          -- Técnico
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) as tecnico,
          
          -- Dados da Tarefa
          tk.begin as data_lancamento,
          (tk.actiontime / 3600) as horas,
          
          -- Tipo de Hora (Lógica: Comercial se entre 08:00 e 18:00 em dias úteis)
          CASE 
            WHEN WEEKDAY(tk.begin) < 5 AND HOUR(tk.begin) BETWEEN 8 AND 17 THEN 'Comercial'
            ELSE 'Plantão'
          END as tipo_hora,
          
          UTC_TIMESTAMP() as data_carga

        FROM glpi_$table tk
        JOIN $parentTable p ON p.id = tk.$fk
        LEFT JOIN glpi_entities e ON e.id = p.entities_id
        LEFT JOIN glpi_users u ON u.id = tk.users_id
        -- Tenta pegar o grupo principal do usuário para o Timesheet
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

    $fullSql = implode(" UNION ALL ", $queries);
    $st = $src->prepare($fullSql);
    $st->execute($params);
    return $st;
  }
}