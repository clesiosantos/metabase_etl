<?php
final class Lock {
  public static function acquire(PDO $pdo, string $name, int $timeoutSec = 1): bool {
    $st = $pdo->prepare("SELECT GET_LOCK(:n,:t) AS l");
    $st->execute([':n' => $name, ':t' => $timeoutSec]);
    $r = $st->fetch();
    return isset($r['l']) && (int)$r['l'] === 1;
  }
  public static function release(PDO $pdo, string $name): void {
    $st = $pdo->prepare("SELECT RELEASE_LOCK(:n)");
    $st->execute([':n' => $name]);
  }
}