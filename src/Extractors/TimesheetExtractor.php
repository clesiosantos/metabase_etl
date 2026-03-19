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

      // Regra de Negócio: Se for Ticket, ignora apenas se for do Formulário 142 (que tem carga própria via fetchForm142Details)
      // Isso evita duplicidade no Form 142, mas permite carregar tarefas de outros formulários (ex: Ticket 43507).
      $filterForms = ($type === 'Ticket') 
        ? "AND p.id NOT IN (
              SELECT it.tickets_id 
              FROM glpi_items_tickets it
              JOIN glpi_plugin_formcreator_formanswers fa ON fa.id = it.items_id
              WHERE it.itemtype = 'PluginFormcreatorFormAnswer'
                AND fa.plugin_formcreator_forms_id = 142
          )" 
        : "";

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
          AND tk.actiontime > 0
          $filterForms
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
          CONCAT('FORM_', t.resposta_id) AS id_tarefa,
          t.resposta_id AS id_tarefa_original,
          t.resposta_id AS id_resposta,
          CONCAT(t.ticket_id, '-', t.resposta_id) AS id_tarefa_formatado,
          'Forms' AS tipo_ticket,
          t.ticket_id AS id_pai,
          tk.date AS data_abertura_pai,
          tk.closedate AS data_fechamento_pai,
          
          MAX(CASE WHEN t.id_pergunta = 1653 THEN t.entidade END) AS cliente,
          MAX(CASE WHEN t.id_pergunta = 1654 THEN t.grupo END) AS grupo_solucionador,
          
          COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) AS tecnico,
          
          MAX(CASE WHEN t.id_pergunta = 1651 THEN t.resposta END) AS data_lancamento,
          t.request_date AS data_criacao_tarefa,

          ROUND(TIMESTAMPDIFF(SECOND,
              MAX(CASE WHEN t.id_pergunta = 1651 THEN t.resposta END),
              MAX(CASE WHEN t.id_pergunta = 1652 THEN t.resposta END)
          ) / 3600, 2) AS horas,

          MAX(CASE WHEN t.id_pergunta = 1655 THEN t.resposta END) AS tipo_hora,
          UTC_TIMESTAMP() AS data_carga

      FROM (
          SELECT
              fa.id AS resposta_id,
              fa.requester_id,
              fa.request_date,
              it.tickets_id AS ticket_id,
              q.id AS id_pergunta,
              a.answer AS resposta,
              e.name AS entidade,
              g.name AS grupo

          FROM glpi_plugin_formcreator_formanswers fa
          JOIN glpi_plugin_formcreator_answers a ON a.plugin_formcreator_formanswers_id = fa.id
          JOIN glpi_plugin_formcreator_questions q ON q.id = a.plugin_formcreator_questions_id
          -- Regra: Remover registros sem ticket pai vinculado (INNER JOIN)
          JOIN glpi_items_tickets it ON it.items_id = fa.id AND it.itemtype = 'PluginFormcreatorFormAnswer'
          LEFT JOIN glpi_entities e ON (q.id = 1653 AND e.id = a.answer)
          LEFT JOIN glpi_groups g ON (q.id = 1654 AND g.id = a.answer)
          WHERE fa.id IN ($placeholders)
            AND q.id IN (1643,1651,1652,1653,1654,1655)
      ) t
      LEFT JOIN glpi_users u ON u.id = t.requester_id
      LEFT JOIN glpi_tickets tk ON tk.id = t.ticket_id
      GROUP BY t.resposta_id, t.ticket_id, u.id, tk.id, t.request_date
      HAVING horas > 0
    ";

    $st = $src->prepare($sql);
    $st->execute($ids);
    return $st;
  }
}