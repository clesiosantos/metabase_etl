<?php
final class TicketsEtl {
  public static function run(PDO $src, PDO $dst, Logger $log, array $etlCfg): void {
    $entity = 'tickets';
    $batchSize = (int)$etlCfg['batch_size'];
    $fullDays  = (int)$etlCfg['window_full_days'];

    $last = Checkpoint::get($dst, $entity) ?? '1970-01-01 00:00:00';
    $fullStart = (new DateTime('now', new DateTimeZone('UTC')))
      ->modify("-{$fullDays} days")->format('Y-m-d H:i:s');

    $log->info("Tickets: calculando universo de IDs", ['last' => $last, 'fullStart' => $fullStart]);

    $idsSql = "
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
    $idsSt = $src->prepare($idsSql);
    $idsSt->execute([':last' => $last, ':full' => $fullStart]);
    $ids = array_map('intval', $idsSt->fetchAll(PDO::FETCH_COLUMN));

    if (!$ids) {
      $log->info("Tickets: nada a processar");
      Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
      return;
    }

    $log->info("Tickets: IDs encontrados", ['count' => count($ids)]);

    $detailTemplate = "
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
        AND t.id IN (%s)
    ";

    $upsert = "
      INSERT INTO metabase_tickets (
        chamado,titulo_chamado,tipo_chamado,
        data_criacao,data_solucao,data_fechamento,data_ultima_atualizacao,
        status_chamado,prioridade,urgencia,impacto,
        status_sla,limite_solucao,limite_atendimento,sla_risco,sla_atendimento_ok,sla_solucao_ok,
        tma_minutos,mttr_minutos,aging_minutos,tempo_primeiro_atendimento_minutos,tempo_espera_minutos,
        servico_completo,grupo_solucionador,agente_solucionador,
        nome_solicitante,nome_tecnico_responsavel,
        entidade_cliente,localizacao_fisica,periodo_avaliado,
        reaberturas,tempo_total_lancados,tem_tecnico_atribuido,tem_prioridade,
        tags,users_id_recipient,locations_id,data_carga
      ) VALUES (
        :chamado,:titulo_chamado,:tipo_chamado,
        :data_criacao,:data_solucao,:data_fechamento,:data_ultima_atualizacao,
        :status_chamado,:prioridade,:urgencia,:impacto,
        :status_sla,:limite_solucao,:limite_atendimento,:sla_risco,:sla_atendimento_ok,:sla_solucao_ok,
        :tma_minutos,:mttr_minutos,:aging_minutos,:tempo_primeiro_atendimento_minutos,:tempo_espera_minutos,
        :servico_completo,:grupo_solucionador,:agente_solucionador,
        :nome_solicitante,:nome_tecnico_responsavel,
        :entidade_cliente,:localizacao_fisica,:periodo_avaliado,
        :reaberturas,:tempo_total_lancados,:tem_tecnico_atribuido,:tem_prioridade,
        :tags,:users_id_recipient,:locations_id,:data_carga
      )
      ON DUPLICATE KEY UPDATE
        titulo_chamado=VALUES(titulo_chamado),
        tipo_chamado=VALUES(tipo_chamado),
        data_criacao=VALUES(data_criacao),
        data_solucao=VALUES(data_solucao),
        data_fechamento=VALUES(data_fechamento),
        data_ultima_atualizacao=VALUES(data_ultima_atualizacao),
        status_chamado=VALUES(status_chamado),
        prioridade=VALUES(prioridade),
        urgencia=VALUES(urgencia),
        impacto=VALUES(impacto),
        status_sla=VALUES(status_sla),
        limite_solucao=VALUES(limite_solucao),
        limite_atendimento=VALUES(limite_atendimento),
        sla_risco=VALUES(sla_risco),
        sla_atendimento_ok=VALUES(sla_atendimento_ok),
        sla_solucao_ok=VALUES(sla_solucao_ok),
        tma_minutos=VALUES(tma_minutos),
        mttr_minutos=VALUES(mttr_minutos),
        aging_minutos=VALUES(aging_minutos),
        tempo_primeiro_atendimento_minutos=VALUES(tempo_primeiro_atendimento_minutos),
        tempo_espera_minutos=VALUES(tempo_espera_minutos),
        servico_completo=VALUES(servico_completo),
        grupo_solucionador=VALUES(grupo_solucionador),
        agente_solucionador=VALUES(agente_solucionador),
        nome_solicitante=VALUES(nome_solicitante),
        nome_tecnico_responsavel=VALUES(nome_tecnico_responsavel),
        entidade_cliente=VALUES(entidade_cliente),
        localizacao_fisica=VALUES(localizacao_fisica),
        periodo_avaliado=VALUES(periodo_avaliado),
        reaberturas=VALUES(reaberturas),
        tempo_total_lancados=VALUES(tempo_total_lancados),
        tem_tecnico_atribuido=VALUES(tem_tecnico_atribuido),
        tem_prioridade=VALUES(tem_prioridade),
        tags=VALUES(tags),
        users_id_recipient=VALUES(users_id_recipient),
        locations_id=VALUES(locations_id),
        data_carga=VALUES(data_carga)
    ";
    $upSt = $dst->prepare($upsert);

    $chunks = array_chunk($ids, $batchSize);
    foreach ($chunks as $i => $chunk) {
      $placeholders = implode(',', array_fill(0, count($chunk), '?'));
      $detailSql = sprintf($detailTemplate, $placeholders);

      $log->info("Tickets: batch", ['batch' => $i + 1, 'size' => count($chunk)]);

      $srcSt = $src->prepare($detailSql);
      $srcSt->execute($chunk);

      $dst->beginTransaction();
      try {
        while ($row = $srcSt->fetch()) {
          $upSt->execute($row);
        }
        $dst->commit();
      } catch (Throwable $e) {
        $dst->rollBack();
        throw $e;
      }
    }

    Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
    $log->info("Tickets: concluído");
  }
}