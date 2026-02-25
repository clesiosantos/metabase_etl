<?php
final class TicketsJob {
  public static function run(PDO $src, PDO $dst, Logger $log, array $cfg): void {
    $entity = 'tickets';
    $batchSize = (int)$cfg['etl']['batch_size'];
    $fullDays  = (int)$cfg['etl']['window_full_days'];

    $last = Checkpoint::get($dst, $entity) ?? '1970-01-01 00:00:00';
    $fullStart = (new DateTime('now', new DateTimeZone('UTC')))
      ->modify("-{$fullDays} days")->format('Y-m-d H:i:s');

    $ids = TicketsExtractor::fetchChangedIds($src, $last, $fullStart);
    if (!$ids) {
      $log->info("TicketsJob: nada a processar");
      Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
      return;
    }

    $upSt = TicketsLoader::upsertStatement($dst);

    $chunks = array_chunk($ids, $batchSize);
    foreach ($chunks as $i => $chunk) {
      $log->info("TicketsJob: batch", ['batch' => $i + 1, 'size' => count($chunk)]);

      $srcSt = TicketsExtractor::fetchDetailsByIds($src, $chunk);

      $dst->beginTransaction();
      try {
        while ($row = $srcSt->fetch()) {
          $row = TicketsTransformer::normalize($row);
          $upSt->execute($row);
        }
        $dst->commit();
      } catch (Throwable $e) {
        $dst->rollBack();
        $log->error("TicketsJob: erro", ['message' => $e->getMessage()]);
        throw $e;
      }
    }

    Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
    $log->info("TicketsJob: concluído", ['count' => count($ids)]);
  }
}