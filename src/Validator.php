<?php
/**
 * Data: 26/02/2026
 * Versão: 1.0.2
 * Autor: 3P Systems — www.3psystems.com.br
 */

declare(strict_types=1);

final class Validator {
  public static function validateTickets(PDO $dst): array {
    $out = [];

    $out['dw_total'] = (int)$dst->query("SELECT COUNT(*) AS c FROM metabase_tickets")->fetch()['c'];

    $sqlFilled = "
      SELECT
        SUM(CASE WHEN categoria IS NOT NULL AND categoria <> '' THEN 1 ELSE 0 END) AS cat_ok,
        SUM(CASE WHEN subcategoria IS NOT NULL AND subcategoria <> '' THEN 1 ELSE 0 END) AS sub_ok,
        SUM(CASE WHEN servico IS NOT NULL AND servico <> '' THEN 1 ELSE 0 END) AS srv_ok,
        SUM(CASE WHEN id_grupo_solucionador IS NOT NULL THEN 1 ELSE 0 END) AS gid_ok,
        SUM(CASE WHEN tipo_contrato IS NOT NULL AND tipo_contrato <> '' THEN 1 ELSE 0 END) AS tipo_contrato_ok,
        SUM(CASE WHEN grupo_solucao IS NOT NULL AND grupo_solucao <> '' THEN 1 ELSE 0 END) AS grupo_solucao_ok,
        SUM(CASE WHEN tipo_atividade IS NOT NULL AND tipo_atividade <> '' THEN 1 ELSE 0 END) AS tipo_atividade_ok,
        SUM(CASE WHEN tipo_solucao IS NOT NULL AND tipo_solucao <> '' THEN 1 ELSE 0 END) AS sol_ok,
        SUM(CASE WHEN disciplina_solucao IS NOT NULL AND disciplina_solucao <> '' THEN 1 ELSE 0 END) AS disc_ok,
        SUM(CASE WHEN modelo_solucao IS NOT NULL AND modelo_solucao <> '' THEN 1 ELSE 0 END) AS mod_ok
      FROM metabase_tickets
    ";
    $out['filled'] = $dst->query($sqlFilled)->fetch();

    $out['closed_without_date'] = (int)$dst->query("
      SELECT COUNT(*) AS c
      FROM metabase_tickets
      WHERE status_chamado = 'Fechado' AND data_fechamento IS NULL
    ")->fetch()['c'];

    $out['null_servico_completo'] = (int)$dst->query("
      SELECT COUNT(*) AS c
      FROM metabase_tickets
      WHERE servico_completo IS NULL
    ")->fetch()['c'];

    $out['group_split_inconsistent'] = (int)$dst->query("
      SELECT COUNT(*) AS c
      FROM metabase_tickets
      WHERE grupo_solucionador LIKE '% > %'
        AND (grupo_solucao IS NULL OR grupo_solucao = '')
    ")->fetch()['c'];

    return $out;
  }
}