<?php
final class ChangesJob {
  public static function run(PDO $src, PDO $dst, string $mode, int $windowFullDays, int $batchSize): void {
    $entity = 'changes';
    $runId = EtlRun::start($dst, $entity, $mode, $windowFullDays, $batchSize, ['metabase_changes']);

    try {
      $lastUtc = Checkpoint::getLastSuccessUtc($dst, $entity);
      if (!$lastUtc || $mode === 'full') {
        $lastUtc = '1970-01-01 00:00:00';
      }

      $ids = ChangesExtractor::fetchChangedIds($src, $lastUtc, $lastUtc);
      $idsSelected = count($ids);
      EtlRun::setSelected($dst, $runId, $idsSelected);

      $upsert = ChangesLoader::upsertStatement($dst);
      $rowsUpserted = 0;

      for ($i = 0; $i < $idsSelected; $i += $batchSize) {
        $chunk = array_slice($ids, $i, $batchSize);
        $st = ChangesExtractor::fetchDetailsByIds($src, $chunk);

        while ($row = $st->fetch(PDO::FETCH_ASSOC)) {
          $bindRow = self::bindRow($row);
          $upsert->execute($bindRow);
          $rowsUpserted++;
          EtlRun::addUpserted($dst, $runId, 1);
        }
      }

      $validation = Validator::validateRun($dst, 'metabase_changes', $rowsUpserted);
      EtlRun::finishSuccess($dst, $runId, $validation);

      Checkpoint::upsertCheckpointNow($dst, $entity);

    } catch (Throwable $e) {
      EtlError::log($dst, $runId, $entity, $e->getMessage(), [
        'exception_class' => get_class($e),
        'file' => $e->getFile(),
        'line' => $e->getLine(),
      ]);
      EtlRun::finishFailed($dst, $runId, $e->getMessage());
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
      ':ttr_em_risco' => $row['ttr_em_risco'] ?? 0,
      ':limite_solucao' => $row['limite_solucao'] ?? null,
      ':mttr_minutos' => $row['mttr_minutos'] ?? null,
      ':aging_minutos' => $row['aging_minutos'] ?? null,
      ':servico_completo' => $row['servico_completo'] ?? null,
      ':categoria' => $row['categoria'] ?? null,
      ':subcategoria' => $row['subcategoria'] ?? null,
      ':servico' => $row['servico'] ?? null,
      ':grupo_solucionador' => $row['grupo_solucionador'] ?? null,
      ':grupo_solucionador_nome' => $row['grupo_solucionador_nome'] ?? null,
      ':id_grupo_solucionador' => $row['id_grupo_solucionador'] ?? null,
      ':tipo_contrato' => $row['tipo_contrato'] ?? null,
      ':grupo_solucao' => $row['grupo_solucao'] ?? null,
      ':tipo_atividade' => $row['tipo_atividade'] ?? null,
      ':agente_solucionador' => $row['agente_solucionador'] ?? null,
      ':nome_solicitante' => $row['nome_solicitante'] ?? null,
      ':entidade_cliente' => $row['entidade_cliente'] ?? null,
      ':localizacao_fisica' => $row['localizacao_fisica'] ?? null,
      ':tags' => $row['tags'] ?? null,
      ':users_id_recipient' => $row['users_id_recipient'] ?? null,
      ':locations_id' => $row['locations_id'] ?? null,
      ':data_carga' => $row['data_carga'] ?? null
    ];
  }
}