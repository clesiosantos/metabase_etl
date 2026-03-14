<?php
final class ProblemsJob {

  public static function run(PDO $src, PDO $dst, string $mode, int $windowFullDays, int $batchSize): void {
    $entity = 'problems';
    $tablesUpdated = ['metabase_problems', 'dim_tags', 'bridge_problem_tags'];

    $runId = EtlRun::start($dst, $entity, $mode, $windowFullDays, $batchSize, $tablesUpdated);

    try {
      $fullStartUtc = gmdate('Y-m-d H:i:s', time() - ($windowFullDays * 86400));

      $lastUtc = Checkpoint::get($dst, $entity);
      if (!$lastUtc || $mode === 'full') {
        $lastUtc = '1970-01-01 00:00:00';
        $fullStartUtc = $lastUtc;
      }

      $ids = ProblemsExtractor::fetchChangedIds($src, $lastUtc, $fullStartUtc);
      $idsSelected = count($ids);
      EtlRun::setSelected($dst, $runId, $idsSelected);

      // TAGS: mantém dim_tags sincronizada e atualiza ponte só para os problemas impactados
      TagsJobs::syncDimTags($src, $dst);
      if ($idsSelected > 0) {
        TagsJobs::refreshProblemLinks($src, $dst, $ids);
      }

      $upsert = ProblemsLoader::upsertStatement($dst);

      for ($i = 0; $i < $idsSelected; $i += $batchSize) {
        $chunk = array_slice($ids, $i, $batchSize);
        $st = ProblemsExtractor::fetchDetailsByIds($src, $chunk);

        while ($row = $st->fetch(PDO::FETCH_ASSOC)) {
          $upsert->execute(self::bindRow($row));
          EtlRun::addUpserted($dst, $runId, 1);
        }
      }

      $validation = self::validate($dst);
      EtlRun::finishSuccess($dst, $runId, $validation, 'OK');

      Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));

    } catch (Throwable $e) {
      EtlError::log($dst, $runId, $entity, $e->getMessage(), [
        'exception_class' => get_class($e),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
      ]);

      EtlRun::finishFailed($dst, $runId, $e->getMessage(), [
        'exception_class' => get_class($e),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
      ]);

      throw $e;
    }
  }

  private static function bindRow(array $row): array {
    return [
      ':chamado' => $row['chamado'] ?? null,
      ':titulo_chamado' => $row['titulo_chamado'] ?? null,

      ':data_criacao' => $row['data_criacao'] ?? null,
      ':data_solucao' => $row['data_solucao'] ?? null,
      ':data_fechamento' => $row['data_fechamento'] ?? null,
      ':data_ultima_atualizacao' => $row['data_ultima_atualizacao'] ?? null,
      ':data_id' => $row['data_id'] ?? null,

      ':status_chamado' => $row['status_chamado'] ?? null,
      ':prioridade' => $row['prioridade'] ?? null,
      ':urgencia' => $row['urgencia'] ?? null,
      ':impacto' => $row['impacto'] ?? null,

      ':ttr_status' => $row['ttr_status'] ?? null,
      ':ttr_em_risco' => isset($row['ttr_em_risco']) ? (int)$row['ttr_em_risco'] : 0,
      ':limite_solucao' => $row['limite_solucao'] ?? null,

      ':mttr_minutos' => $row['mttr_minutos'] ?? null,
      ':aging_minutos' => $row['aging_minutos'] ?? null,

      ':servico_completo' => $row['servico_completo'] ?? null,
      ':categoria' => $row['categoria'] ?? null,
      ':subcategoria' => $row['subcategoria'] ?? null,
      ':servico' => $row['servico'] ?? null,

      ':tipo_solucao' => $row['tipo_solucao'] ?? null,
      ':disciplina_solucao' => $row['disciplina_solucao'] ?? null,
      ':modelo_solucao' => $row['modelo_solucao'] ?? null,

      ':grupo_solucionador' => $row['grupo_solucionador'] ?? null,
      ':grupo_solucionador_nome' => $row['grupo_solucionador_nome'] ?? null,
      ':id_grupo_solucionador' => $row['id_grupo_solucionador'] ?? null,
      ':tipo_contrato' => $row['tipo_contrato'] ?? null,
      ':grupo_solucao' => $row['grupo_solucao'] ?? null,
      ':tipo_atividade' => $row['tipo_atividade'] ?? null,

      ':causa_raiz' => $row['causa_raiz'] ?? null,

      ':agente_solucionador' => $row['agente_solucionador'] ?? null,
      ':nome_solicitante' => $row['nome_solicitante'] ?? null,

      ':entidade_cliente' => $row['entidade_cliente'] ?? null,
      ':localizacao_fisica' => $row['localizacao_fisica'] ?? null,

      ':tags' => $row['tags'] ?? null,

      ':users_id_recipient' => $row['users_id_recipient'] ?? null,
      ':locations_id' => $row['locations_id'] ?? null,

      ':data_carga' => $row['data_carga'] ?? gmdate('Y-m-d H:i:s'),
    ];
  }

  private static function validate(PDO $dst): array {
    $out = [
      'table' => 'metabase_problems',
      'checked_at' => gmdate('Y-m-d H:i:s'),
      'null_rates' => [],
      'ttr_status_distribution' => [],
    ];

    $st = $dst->query("
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN data_id IS NULL THEN 1 ELSE 0 END) AS nulls
      FROM metabase_problems
    ");
    $r = $st->fetch(PDO::FETCH_ASSOC);
    $total = (int)($r['total'] ?? 0);
    $nulls = (int)($r['nulls'] ?? 0);
    $out['null_rates']['data_id'] = $total > 0 ? round(100 * $nulls / $total, 2) : null;

    $st = $dst->query("
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN entidade_cliente IS NULL OR entidade_cliente = '' THEN 1 ELSE 0 END) AS nulls
      FROM metabase_problems
    ");
    $r = $st->fetch(PDO::FETCH_ASSOC);
    $total = (int)($r['total'] ?? 0);
    $nulls = (int)($r['nulls'] ?? 0);
    $out['null_rates']['entidade_cliente'] = $total > 0 ? round(100 * $nulls / $total, 2) : null;

    $st = $dst->query("
      SELECT ttr_status, COUNT(*) AS qtd
      FROM metabase_problems
      GROUP BY ttr_status
      ORDER BY qtd DESC
    ");
    while ($r = $st->fetch(PDO::FETCH_ASSOC)) {
      $out['ttr_status_distribution'][] = [
        'value' => $r['ttr_status'],
        'count' => (int)$r['qtd']
      ];
    }

    return $out;
  }
}