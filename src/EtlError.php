<?php
final class EtlError {
  public static function log(PDO $dst, ?int $runId, string $entity, string $message, array $ctx = []): void {
    $st = $dst->prepare("
      INSERT INTO etl_error (run_id, error_at, entity_name, message, context_json)
      VALUES (:run_id, UTC_TIMESTAMP(), :entity, :msg, :ctx)
    ");
    $st->execute([
      ':run_id' => $runId,
      ':entity' => $entity,
      ':msg' => $message,
      ':ctx' => $ctx ? json_encode($ctx, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
    ]);
  }
}