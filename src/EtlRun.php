<?php
final class EtlRun {
  public static function start(PDO $dst, string $entity, string $mode, int $windowDays, int $batchSize, array $tablesUpdated): int {
    $st = $dst->prepare("
      INSERT INTO etl_run (started_at, status, mode, entity_name, window_full_days, batch_size, tables_updated)
      VALUES (UTC_TIMESTAMP(), 'RUNNING', :mode, :entity, :days, :batch, :tables)
    ");
    $st->execute([
      ':mode' => $mode,
      ':entity' => $entity,
      ':days' => $windowDays,
      ':batch' => $batchSize,
      ':tables' => implode(',', $tablesUpdated),
    ]);
    return (int)$dst->lastInsertId();
  }

  public static function setSelected(PDO $dst, int $runId, int $idsSelected): void {
    $st = $dst->prepare("UPDATE etl_run SET ids_selected=:n WHERE run_id=:id");
    $st->execute([':n' => $idsSelected, ':id' => $runId]);
  }

  public static function addUpserted(PDO $dst, int $runId, int $delta): void {
    $st = $dst->prepare("UPDATE etl_run SET rows_upserted = rows_upserted + :d WHERE run_id=:id");
    $st->execute([':d' => $delta, ':id' => $runId]);
  }

  public static function finishSuccess(PDO $dst, int $runId, array $validation, ?string $message = null): void {
    $st = $dst->prepare("
      UPDATE etl_run
      SET finished_at=UTC_TIMESTAMP(),
          status='SUCCESS',
          validation_json=:v,
          message=:m
      WHERE run_id=:id
    ");
    $st->execute([
      ':v' => json_encode($validation, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
      ':m' => $message,
      ':id' => $runId
    ]);
  }

  public static function finishFailed(PDO $dst, int $runId, string $message, array $ctx = []): void {
    $st = $dst->prepare("
      UPDATE etl_run
      SET finished_at=UTC_TIMESTAMP(),
          status='FAILED',
          message=:m,
          validation_json=:v
      WHERE run_id=:id
    ");
    $st->execute([
      ':m' => $message,
      ':v' => json_encode(['error_context' => $ctx], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
      ':id' => $runId
    ]);
  }
}