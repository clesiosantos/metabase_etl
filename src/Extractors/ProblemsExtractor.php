<?php
final class ProblemsExtractor {
  public static function fetchChangedIds(PDO $src, string $lastUtc, string $fullStartUtc): array {
    $sql = "
      SELECT DISTINCT id
      FROM glpi_problems
      WHERE is_deleted = 0
        AND date_mod >= ?
    ";
    $st = $src->prepare($sql);
    $st->execute([$lastUtc]);
    return array_map('intval', $st->fetchAll(PDO::FETCH_COLUMN));
  }

  public static function fetchDetailsByIds(PDO $src, array $ids): PDOStatement {
    if (!$ids) {
      throw new RuntimeException("Lista de IDs vazia em fetchDetailsByIds()");
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));

    $sql = "
      SELECT
        p.id AS chamado,
        p.name AS titulo_chamado,

        p.date AS data_criacao,
        p.solvedate AS data_solucao,
        p.closedate AS data_fechamento,
        p.date_mod AS data_ultima_atualizacao,
        DATE(p.date) AS data_id,

        CASE p.status
            WHEN 1 THEN 'Novo'
            WHEN 2 THEN 'Em andamento'
            WHEN 3 THEN 'Em planejamento'
            WHEN 4 THEN 'Pendente'
            WHEN 5 THEN 'Resolvido'
            WHEN 6 THEN 'Fechado'
            ELSE 'Outro'
        END AS status_chamado,

        CAST(p.priority AS CHAR) AS prioridade,
        CAST(p.urgency AS CHAR) AS urgencia,
        CAST(p.impact AS CHAR) AS impacto,

        CASE
          WHEN p.time_to_resolve IS NULL THEN 'SEM SLA'
          WHEN p.solvedate IS NULL AND UTC_TIMESTAMP() > p.time_to_resolve THEN 'FORA DO PRAZO'
          WHEN p.solvedate IS NOT NULL AND p.solvedate > p.time_to_resolve THEN 'FORA DO PRAZO'
          WHEN p.solvedate IS NULL
               AND UTC_TIMESTAMP() <= p.time_to_resolve
               AND TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), p.time_to_resolve) <= 120
            THEN 'EM RISCO'
          ELSE 'NO PRAZO'
        END AS ttr_status,

        CASE
          WHEN p.solvedate IS NULL
           AND p.time_to_resolve IS NOT NULL
           AND UTC_TIMESTAMP() <= p.time_to_resolve
           AND TIMESTAMPDIFF(MINUTE, UTC_TIMESTAMP(), p.time_to_resolve) <= 120
          THEN 1 ELSE 0
        END AS ttr_em_risco,

        p.time_to_resolve AS limite_solucao,

        CASE
          WHEN p.solvedate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, p.date, p.solvedate)
        END AS mttr_minutos,

        CASE
          WHEN p.solvedate IS NOT NULL THEN TIMESTAMPDIFF(MINUTE, p.date, p.solvedate)
          ELSE TIMESTAMPDIFF(MINUTE, p.date, UTC_TIMESTAMP())
        END AS aging_minutos,

        ic.completename AS servico_completo,
        SUBSTRING_INDEX(ic.completename, ' > ', 1) AS categoria,
        SUBSTRING_INDEX(SUBSTRING_INDEX(ic.completename, ' > ', 2), ' > ', -1) AS subcategoria,
        SUBSTRING_INDEX(ic.completename, ' > ', -1) AS servico,
        
        styp.name AS tipo_solucao,

        NULL AS grupo_solucionador,
        NULL AS grupo_solucionador_nome,
        NULL AS id_grupo_solucionador,
        NULL AS tipo_contrato,
        NULL AS grupo_solucao,
        NULL AS tipo_atividade,

        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(utech.firstname,''),' ',IFNULL(utech.realname,''))),''), utech.name) AS agente_solucionador,

        COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u_req.firstname,''),' ',IFNULL(u_req.realname,''))),''), u_req.name) AS nome_solicitante,

        e.name AS entidade_cliente,
        l.name AS localizacao_fisica,

        tagg.tags AS tags,

        p.users_id_recipient,
        p.locations_id,

        UTC_TIMESTAMP() AS data_carga

      FROM glpi_problems p
      LEFT JOIN glpi_itilcategories ic ON ic.id = p.itilcategories_id
      LEFT JOIN glpi_entities e ON e.id = p.entities_id
      LEFT JOIN glpi_locations l ON l.id = p.locations_id
      LEFT JOIN glpi_users u_req ON u_req.id = p.users_id_recipient
      
      -- Join para Modelo de Solução
      LEFT JOIN glpi_itilsolutions isol ON (isol.items_id = p.id AND isol.itemtype = 'Problem')
      LEFT JOIN glpi_solutiontypes styp ON styp.id = isol.solutiontypes_id

      LEFT JOIN (
        SELECT problems_id, MIN(users_id) AS users_id
        FROM glpi_problems_users
        WHERE type = 2
        GROUP BY problems_id
      ) pu1 ON pu1.problems_id = p.id
      LEFT JOIN glpi_users utech ON utech.id = pu1.users_id

      LEFT JOIN (
        SELECT
          ti.items_id AS problem_id,
          GROUP_CONCAT(tg.name ORDER BY tg.name SEPARATOR ', ') AS tags
        FROM glpi_plugin_tag_tagitems ti
        JOIN glpi_plugin_tag_tags tg ON tg.id = ti.plugin_tag_tags_id
        WHERE ti.itemtype = 'Problem'
          AND tg.is_active = 1
        GROUP BY ti.items_id
      ) tagg ON tagg.problem_id = p.id

      WHERE p.is_deleted = 0
        AND p.id IN ($placeholders)
    ";

    $st = $src->prepare($sql);
    $st->execute(array_values($ids));
    return $st;
  }
}