<?php
final class Validator {
  public static function validateTickets(PDO $dst): array {
    $out = [];

    // 1) Total de linhas
    $out['dw_total'] = (int)$dst->query("SELECT COUNT(*) AS c FROM metabase_tickets")->fetch()['c'];

    // 2) Linhas com colunas novas preenchidas
    $sqlFilled = "
      SELECT
        SUM(CASE WHEN categoria IS NOT NULL AND categoria <> '' THEN 1 ELSE 0 END) AS cat_ok,
        SUM(CASE WHEN subcategoria IS NOT NULL AND subcategoria <> '' THEN 1 ELSE 0 END) AS sub_ok,
        SUM(CASE WHEN servico IS NOT NULL AND servico <> '' THEN 1 ELSE 0 END) AS srv_ok,
        SUM(CASE WHEN id_grupo_solucionador IS NOT NULL THEN 1 ELSE 0 END) AS gid_ok,
        SUM(CASE WHEN tipo_atividade IS NOT NULL AND tipo_atividade <> '' THEN 1 ELSE 0 END) AS ta_ok,
        SUM(CASE WHEN tipo_contrato IS NOT NULL AND tipo_contrato <> '' THEN 1 ELSE 0 END) AS tc_ok,
        SUM(CASE WHEN grupo_solucao IS NOT NULL AND grupo_solucao <> '' THEN 1 ELSE 0 END) AS gs_ok
      FROM metabase_tickets
    ";
    $out['filled'] = $dst->query($sqlFilled)->fetch();

    // 3) Sanity: status “Fechado” com data_fechamento nula (indício de inconsistência)
    $out['closed_without_date'] = (int)$dst->query("
      SELECT COUNT(*) AS c
      FROM metabase_tickets
      WHERE status_chamado = 'Fechado' AND data_fechamento IS NULL
    ")->fetch()['c'];

    // 4) Sanity: tickets com serviço_completo nulo (indício de categoria não vinculada)
    $out['null_servico_completo'] = (int)$dst->query("
      SELECT COUNT(*) AS c
      FROM metabase_tickets
      WHERE servico_completo IS NULL
    ")->fetch()['c'];

    return $out;
  }
}