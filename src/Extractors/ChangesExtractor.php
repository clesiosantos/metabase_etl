<?php
final class ChangesExtractor {
  public static function fetchChangedIds(PDO $src, string $lastUtc, string $fullStartUtc): array {
    $sql = "
      SELECT DISTINCT id
      FROM glpi_changes
      WHERE is_deleted = 0
        AND (
          date_mod >= ?
          OR `date` >= ?
          OR solvedate >= ?
          OR closedate >= ?
        )
    ";
    $st = $src->prepare($sql);
    $st->execute([$lastUtc, $fullStartUtc, $fullStartUtc, $fullStartUtc]);
    return array_map('intval', $st->fetchAll(PDO::FETCH_COLUMN));
  }

  public static function fetchDetailsByIds(PDO $src, array $ids): PDOStatement {
    if (!$ids) {
      throw new RuntimeException("Lista de IDs vazia em fetchDetailsByIds()");
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));

    $sql = "
      SELECT
        c.id AS chamado,
        c.name AS titulo_chamado,

        c.date AS data_criacao,
        c.solvedate AS data_solucao,
        c.closedate AS data_fechamento,
        c.date_mod AS data_ultima_atualizacao,
        DATE(c.date) AS data_id,

        CASE c.status
            WHEN 1 THEN 'Novo'
            WHEN 9 THEN 'Avaliação'
            WHEN 10 THEN 'Aprovação'
            WHEN 7 THEN 'Aceito'
            WHEN 4 THEN 'Pendente'
            WHEN 11 THEN 'Testando'
            WHEN 12 THEN 'Qualificação'
            WHEN 8 THEN 'Revisão'
            WHEN 5 THEN 'Aplicado'
            WHEN 14 THEN 'Cancelado'
            WHEN 13 THEN 'Recusado'
            WHEN 6 THEN 'Fechado'
            ELSE 'Outro'
        END AS status_chamado,

        CAST(c.priority AS CHAR) AS prioridade,
        CAST(c.urgency AS CHAR) AS urgencia,
        CAST(c.impact AS CHAR) AS impacto,

        CASE
          WHEN c.time_to_resolve IS NULL THEN 'SEM SLA'
          WHEN c.solvedate IS NULL AND UTC_TIMESTAMP() > c.time_to_resolve THEN 'FORA DO PRAZO'
          WHEN c.solvedate IS NOT NULL AND c.solvedate > c.time_to_resolve THEN 'FORA DO PRAZO'
          WHEN c.solvedate IS NULL
               AND UTC_TIMESTAMP() <= c.time_to_resolve
               AND TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), c.time_to_resolve) <= 120
            THEN 'EM RISCO'
          ELSE 'NO PRAZO'
        END AS ttr_status,

        CASE
          WHEN c.solvedate IS NULL
           AND c.time_to_resolve IS NOT NULL
           AND UTC_TIMESTAMP() <= c.time_to_resolve
           AND TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), c.time_to_resolve) <= 120
          THEN 1 ELSE 0
        END AS ttr_em_risco,

        c.time_to_resolve AS limite_solucao,

        CASE
          WHEN c.solvedate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, c.date, c.solvedate)
        END AS mttr_minutos,

        CASE
          WHEN c.solvedate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, c.date, c.solvedate)
          ELSE TIMESTAMPDIFF(MINUTE, c.date, UTC_TIMESTAMP())
        END AS aging_minutos,

        ic.completename AS servico_completo,
        SUBSTRING_INDEX(ic.completename, ' > ', 1) AS categoria,
        SUBSTRING_INDEX(SUBSTRING_INDEX(ic.completename, ' > ', 2), ' > ', -1) AS subcategoria,
        SUBSTRING_INDEX(ic.completename, ' > ', -1) AS servico,

        styp.name AS tipo_solucao,
        CASE WHEN styp.name LIKE '%::%' THEN SUBSTRING_INDEX(styp.name, '::', 1) ELSE NULL END AS disciplina_solucao,
        CASE WHEN styp.name LIKE '%::%' THEN SUBSTRING_INDEX(styp.name, '::', -1) ELSE styp.name END AS modelo_solucao,

        gsol.completename AS grupo_solucionador,
        gsol.name AS grupo_solucionador_nome,
        gsol.id AS id_grupo_solucionador,
        SUBSTRING_INDEX(gsol.completename, ' > ', 1) AS tipo_contrato,
        SUBSTRING_INDEX(SUBSTRING_INDEX(gsol.completename, ' > ', 2), ' > ', -1) AS grupo_solucao,
        SUBSTRING_INDEX(gsol.completename, ' > ', -1) AS tipo_atividade,

        -- Campos adicionais (Plugin Fields - Gestão de Mudanças)
        cf.name AS classificacao,
        ct.name AS classificacao_tecnica,
        amb.name AS ambiente,
        f.datainiciomudanafield AS data_inicio_mudanca,
        f.datafimmudanafield AS data_fim_mudanca,
        f.justificativafield AS justificativa,
        f.impactoaonegociofield AS impacto_negocio,

        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(utech.firstname,''),' ',IFNULL(utech.realname,''))),''), utech.name) AS agente_solucionador,

        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u_req.firstname,''),' ',IFNULL(u_req.realname,''))),''), u_req.name) AS nome_solicitante,

        e.name AS entidade_cliente,
        l.name AS localizacao_fisica,

        tagg.tags AS tags,

        c.users_id_recipient,
        c.locations_id,

        UTC_TIMESTAMP() AS data_carga

      FROM glpi_changes c
      LEFT JOIN glpi_itilcategories ic ON ic.id = c.itilcategories_id
      LEFT JOIN glpi_entities e ON e.id = c.entities_id
      LEFT JOIN glpi_locations l ON l.id = c.locations_id
      LEFT JOIN glpi_users u_req ON u_req.id = c.users_id_recipient

      -- Plugin Fields - Gestão de Mudanças
      LEFT JOIN glpi_plugin_fields_changegestodemudanas f ON f.items_id = c.id
      LEFT JOIN glpi_plugin_fields_classificaofielddropdowns cf ON cf.id = f.plugin_fields_classificaofielddropdowns_id
      LEFT JOIN glpi_plugin_fields_classificaotecnicafielddropdowns ct ON ct.id = f.plugin_fields_classificaotecnicafielddropdowns_id
      LEFT JOIN glpi_plugin_fields_ambientefielddropdowns amb ON amb.id = f.plugin_fields_ambientefielddropdowns_id
      
      -- Join para Modelo de Solução
      LEFT JOIN glpi_itilsolutions isol ON (isol.items_id = c.id AND isol.itemtype = 'Change')
      LEFT JOIN glpi_solutiontypes styp ON styp.id = isol.solutiontypes_id

      LEFT JOIN (
        SELECT changes_id, MIN(groups_id) AS groups_id
        FROM glpi_changes_groups
        WHERE type = 2
        GROUP BY changes_id
      ) cg1 ON cg1.changes_id = c.id
      LEFT JOIN glpi_groups gsol ON gsol.id = cg1.groups_id

      LEFT JOIN (
        SELECT changes_id, MIN(users_id) AS users_id
        FROM glpi_changes_users
        WHERE type = 2
        GROUP BY changes_id
      ) cu1 ON cu1.changes_id = c.id
      LEFT JOIN glpi_users utech ON utech.id = cu1.users_id

      LEFT JOIN (
        SELECT
          ti.items_id AS change_id,
          GROUP_CONCAT(tg.name ORDER BY tg.name SEPARATOR ', ') AS tags
        FROM glpi_plugin_tag_tagitems ti
        JOIN glpi_plugin_tag_tags tg ON tg.id = ti.plugin_tag_tags_id
        WHERE ti.itemtype = 'Change'
          AND tg.is_active = 1
        GROUP BY ti.items_id
      ) tagg ON tagg.change_id = c.id

      WHERE c.is_deleted = 0
        AND c.id IN ($placeholders)
    ";

    $st = $src->prepare($sql);
    $st->execute(array_values($ids));
    return $st;
  }
}