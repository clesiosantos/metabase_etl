<?php
final class TicketsJob {
  public static function run(PDO $src, PDO $dst, Logger $log, array $cfg, string $mode = 'incremental'): void {
    $entity = 'tickets';
    $tablesUpdated = [
      'dw_glpi.metabase_tickets',
      'dw_glpi.dim_tags',
      'dw_glpi.bridge_ticket_tags',
      'dw_glpi.etl_checkpoint',
      'dw_glpi.etl_run',
      'dw_glpi.etl_error'
    ];

    $batchSize = (int)$cfg['etl']['batch_size'];
    $fullDays  = (int)$cfg['etl']['window_full_days'];

    $startedAt = microtime(true);

    $runId = EtlRun::start($dst, $entity, $mode, $fullDays, $batchSize, $tablesUpdated);
    $log->info("TicketsJob: início", ['run_id' => $runId, 'mode' => $mode, 'full_days' => $fullDays, 'batch' => $batchSize]);

    try {
      $fullStart = (new DateTime('now', new DateTimeZone('UTC')))
        ->modify("-{$fullDays} days")->format('Y-m-d H:i:s');

      $last = ($mode === 'full')
        ? '1970-01-01 00:00:00'
        : (Checkpoint::get($dst, $entity) ?? '1970-01-01 00:00:00');

      $log->info("TicketsJob: janela", ['run_id' => $runId, 'checkpoint_last' => $last, 'full_start' => $fullStart]);

      $ids = TicketsExtractor::fetchChangedIds($src, $last, $fullStart);
      $idsSelected = count($ids);

      EtlRun::setSelected($dst, $runId, $idsSelected);
      $log->info("TicketsJob: ids selecionados", ['run_id' => $runId, 'ids' => $idsSelected]);

      // Sincroniza dimensão de tags sempre
      TagsJob::syncTags($src, $dst, $log, $runId);

      if ($idsSelected === 0) {
        $validation = Validator::validateTickets($dst);
        EtlRun::finishSuccess($dst, $runId, $validation, "Nada a processar");
        Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
        $elapsed = round(microtime(true) - $startedAt, 3);
        $log->info("TicketsJob: fim (sem carga)", ['run_id' => $runId, 'elapsed_sec' => $elapsed]);
        return;
      }

      // Sincroniza ponte ticket-tags para tickets impactados
      TagsJob::syncTicketTagLinks($src, $dst, $log, $ids, $runId);

      $upSt = TicketsLoader::upsertStatement($dst);

      $chunks = array_chunk($ids, $batchSize);
      foreach ($chunks as $i => $chunk) {
        $batchStart = microtime(true);
        $log->info("TicketsJob: batch", ['run_id' => $runId, 'batch' => $i + 1, 'size' => count($chunk)]);

        $srcSt = TicketsExtractor::fetchDetailsByIds($src, $chunk);

        $dst->beginTransaction();
        $upsertedThisBatch = 0;

        try {
          while ($row = $srcSt->fetch(PDO::FETCH_ASSOC)) {
            $row = TicketsTransformer::normalize($row);
            $upSt->execute($row);
            $upsertedThisBatch += (int)$upSt->rowCount();
          }
          $dst->commit();
        } catch (Throwable $e) {
          $dst->rollBack();
          EtlError::log($dst, $runId, $entity, $e->getMessage(), ['batch' => $i + 1]);
          throw $e;
        }

        EtlRun::addUpserted($dst, $runId, $upsertedThisBatch);

        $batchElapsed = round(microtime(true) - $batchStart, 3);
        $log->info("TicketsJob: batch fim", [
          'run_id' => $runId,
          'batch' => $i + 1,
          'upsert_rowcount_sum' => $upsertedThisBatch,
          'elapsed_sec' => $batchElapsed
        ]);
      }

      Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));

      $validation = Validator::validateTickets($dst);

      $elapsed = round(microtime(true) - $startedAt, 3);
      $log->info("TicketsJob: concluído", [
        'run_id' => $runId,
        'ids_selected' => $idsSelected,
        'elapsed_sec' => $elapsed,
        'tables_updated' => implode(',', $tablesUpdated),
        'validation' => $validation
      ]);

      EtlRun::finishSuccess($dst, $runId, $validation, "Carga finalizada em {$elapsed}s");
    } catch (Throwable $e) {
      $elapsed = round(microtime(true) - $startedAt, 3);
      $log->error("TicketsJob: falhou", ['run_id' => $runId ?? null, 'elapsed_sec' => $elapsed, 'message' => $e->getMessage()]);
      if (isset($runId) && $runId > 0) {
        EtlRun::finishFailed($dst, $runId, $e->getMessage(), ['elapsed_sec' => $elapsed]);
      }
      throw $e;
    }
  }
}