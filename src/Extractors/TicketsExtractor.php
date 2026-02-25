<?php
final class TicketsExtractor {
  public static function fetchChangedIds(PDO $src, string $lastUtc, string $fullStartUtc): array {
    $sql = "
      SELECT DISTINCT id
      FROM glpi_tickets
      WHERE is_deleted = 0
        AND (
          date_mod >= :last
          OR `date` >= :full
          OR solvedate >= :full
          OR closedate >= :full
        )
    ";
    $st = $src->prepare($sql);
    $st->execute([':last' => $lastUtc, ':full' => $fullStartUtc]);
    return array_map('intval', $st->fetchAll(PDO::FETCH_COLUMN));
  }

  public static function fetchDetailsByIds(PDO $src, array $ids): PDOStatement {
    $placeholders = implode(',', array_fill(0, count($ids), '?'));

    $sql = "
      SELECT
        t.id AS chamado,
        t.name AS titulo_chamado,
        CASE t.type WHEN 1 THEN 'Incidente' WHEN 2 THEN 'Requisição' ELSE 'Outro' END AS tipo_chamado,

        t.date AS data_criacao,
        t.solvedate AS data_solucao,
        t.closedate AS data_fechamento,
        t.date_mod AS data_ultima_atualizacao,

        CASE t.status
          WHEN 1 THEN 'Novo'
          WHEN 2 THEN 'Processando atribuído'
          WHEN 3 THEN 'Processando planejado'
          WHEN 4 THEN 'Pendente'
          WHEN 5 THEN 'Solucionado'
          WHEN 6 THEN 'Fechado'
          ELSE 'Outro'
        END AS status_chamado,

        CAST(t.priority AS CHAR) AS prioridade,
        CAST(t.urgency AS CHAR) AS urgencia,
        CAST(t.impact AS CHAR) AS impacto,

        CASE
          WHEN t.time_to_resolve IS NULL AND t.time_to_own IS NULL THEN 'SEM SLA'
          WHEN t.status <> 6 AND t.time_to_resolve IS NOT NULL AND UTC_TIMESTAMP() > t.time_to_resolve THEN 'SLA FORA DO PRAZO'
          WHEN (t.time_to_resolve IS NOT NULL AND t.solvedate IS NOT NULL AND t.solvedate > t.time_to_resolve) THEN 'SLA FORA DO PRAZO'
          WHEN (
            t.status <> 6
            AND t.time_to_resolve IS NOT NULL
            AND UTC_TIMESTAMP() <= t.time_to_resolve
            AND TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), t.time_to_resolve) <= 120
          ) THEN 'SLA EM RISCO'
          ELSE 'SLA NO PRAZO'
        END AS status_sla,

        t.time_to_resolve AS limite_solucao,
        t.time_to_own AS limite_atendimento,

        CASE
          WHEN t.status <> 6
           AND t.time_to_resolve IS NOT NULL
           AND UTC_TIMESTAMP() <= t.time_to_resolve
           AND TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), t.time_to_resolve) <= 120
          THEN 1 ELSE 0
        END AS sla_risco,

        CASE
          WHEN t.time_to_own IS NULL OR t.takeintoaccountdate IS NULL THEN NULL
          WHEN t.takeintoaccountdate <= t.time_to_own THEN 1 ELSE 0
        END AS sla_atendimento_ok,

        CASE
          WHEN t.time_to_resolve IS NULL OR t.solvedate IS NULL THEN NULL
          WHEN t.solvedate <= t.time_to_resolve THEN 1 ELSE 0
        END AS sla_solucao_ok,

        CASE WHEN t.takeintoaccountdate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, t.date, t.takeintoaccountdate) END AS tma_minutos,
        CASE WHEN t.solvedate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, t.date, t.solvedate) END AS mttr_minutos,

        CASE
          WHEN t.closedate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, t.date, t.closedate)
          ELSE TIMESTAMPDIFF(MINUTE, t.date, UTC_TIMESTAMP())
        END AS aging_minutos,

        CASE WHEN t.takeintoaccountdate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, t.date, t.takeintoaccountdate) END AS tempo_primeiro_atendimento_minutos,

        (t.sla_waiting_duration/60) AS tempo_espera_minutos,

        ic.completename AS servico_completo,

        gsol.name AS grupo_solucionador,

        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(utech.firstname,''),' ',IFNULL(utech.realname,''))),''), utech.name) AS agente_solucionador,

        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u_req.firstname,''),' ',IFNULL(u_req.realname,''))),''), u_req.name) AS nome_solicitante,
        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(utech.firstname,''),' ',IFNULL(utech.realname,''))),''), utech.name) AS nome_tecnico_responsavel,

        e.name AS entidade_cliente,
        l.name AS localizacao_fisica,

        DATE_FORMAT(CASE WHEN DAY(t.date) >= 23 THEN t.date ELSE (t.date - INTERVAL 1 MONTH) END,'%Y-%m') AS periodo_avaliado,

        0 AS reaberturas,

        CASE WHEN ttsk.total_actiontime_seg IS NOT NULL THEN (ttsk.total_actiontime_seg/3600) END AS tempo_total_lancados,

        CASE WHEN tu1.users_id IS NOT NULL THEN 1 ELSE 0 END AS tem_tecnico_atribuido,
        CASE WHEN t.priority IS NOT NULL AND t.priority <> 0 THEN 1 ELSE 0 END AS tem_prioridade,

        tagg.tags AS tags,

        t.users_id_recipient,
        t.locations_id,

        UTC_TIMESTAMP() AS data_carga

      FROM glpi_tickets t
      LEFT JOIN glpi_itilcategories ic ON ic.id = t.itilcategories_id
      LEFT JOIN glpi_entities e ON e.id = t.entities_id
      LEFT JOIN glpi_locations l ON l.id = t.locations_id
      LEFT JOIN glpi_users u_req ON u_req.id = t.users_id_recipient

      LEFT JOIN (
        SELECT tickets_id, MIN(groups_id) AS groups_id
        FROM glpi_groups_tickets
        WHERE type = 2
        GROUP BY tickets_id
      ) gt1 ON gt1.tickets_id = t.id
      LEFT JOIN glpi_groups gsol ON gsol.id = gt1.groups_id

      LEFT JOIN (
        SELECT tickets_id, MIN(users_id) AS users_id
        FROM glpi_tickets_users
        WHERE type = 2
        GROUP BY tickets_id
      ) tu1 ON tu1.tickets_id = t.id
      LEFT JOIN glpi_users utech ON utech.id = tu1.users_id

      LEFT JOIN (
        SELECT tickets_id, SUM(COALESCE(actiontime,0)) AS total_actiontime_seg
        FROM glpi_tickettasks
        GROUP BY tickets_id
      ) ttsk ON ttsk.tickets_id = t.id

      LEFT JOIN (
        SELECT ti.items_id AS ticket_id,
               GROUP_CONCAT(tg.name ORDER BY tg.name SEPARATOR ', ') AS tags
        FROM glpi_plugin_tag_tagitems ti
        JOIN glpi_plugin_tag_tags tg ON tg.id = ti.plugin_tag_tags_id
        WHERE ti.itemtype = 'Ticket' AND tg.is_active = 1
        GROUP BY ti.items_id
      ) tagg ON tagg.ticket_id = t.id

      WHERE t.is_deleted = 0
        AND t.id IN ($placeholders)
    ";

    $st = $src->prepare($sql);
    $st->execute($ids);
    return $st;
  }
}