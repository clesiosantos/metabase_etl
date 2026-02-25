<?php
final class Checkpoint {
  public static function get(PDO $pdo, string $entity): ?string {
    $st = $pdo->prepare("SELECT last_success_at FROM etl_checkpoint WHERE entity_name=:e");
    $st->execute([':e' => $entity]);
    $r = $st->fetch();
    return $r ? $r['last_success_at'] : null;
  }

  public static function set(PDO $pdo, string $entity, string $dtUtc): void {
    $st = $pdo->prepare("
      INSERT INTO etl_checkpoint(entity_name,last_success_at)
      VALUES(:e,:dt)
      ON DUPLICATE KEY UPDATE last_success_at=VALUES(last_success_at)
    ");
    $st->execute([':e' => $entity, ':dt' => $dtUtc]);
  }
}