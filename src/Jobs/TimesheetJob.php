<?php
declare(strict_types=1);

final class TimesheetJob {
  public static function run(PDO $src, PDO $dst, string $mode, int $batchSize): void {
    $entity = 'timesheet';
    $runId = EtlRun::start($dst, $entity, $mode, 0, $batchSize, ['metabase_timesheet']);

    try {
      $lastUtc = ($mode === 'full') ? '1970-01-01 00:00:00' : (Checkpoint::get($dst, $entity) ?? '1970-01-01 00:00:00');
      
      $tasks = TimesheetExtractor::fetchChangedTaskIds($src, $lastUtc);
      $total = count($tasks);
      EtlRun::setSelected($dst, $runId, $total);

      if ($total > 0) {
        $upsert = TimesheetLoader::upsertStatement($dst);
        $chunks = array_chunk($tasks, $batchSize);

        foreach ($chunks as $chunk) {
          $st = TimesheetExtractor::fetchTaskDetails($src, $chunk);
          $dst->beginTransaction();
          while ($row = $st->fetch(PDO::FETCH_ASSOC)) {
            $upsert->execute($row);
            EtlRun::addUpserted($dst, $runId, 1);
          }
          $dst->commit();
        }
      }

      Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
      EtlRun::finishSuccess($dst, $runId, [], 'OK');
    } catch (Throwable $e) {
      if ($dst->inTransaction()) $dst->rollBack();
      EtlRun::finishFailed($dst, $runId, $e->getMessage());
      throw $e;
    }
  }
}