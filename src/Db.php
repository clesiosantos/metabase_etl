<?php
final class Db {
  public static function pdo(array $cfg): PDO {
    $dsn = sprintf(
      'mysql:host=%s;port=%d;dbname=%s;charset=%s',
      $cfg['host'], $cfg['port'], $cfg['db'], $cfg['charset'] ?? 'utf8mb4'
    );

    $pdo = new PDO($dsn, $cfg['user'], $cfg['pass'], [
      PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
      PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    $pdo->exec("SET SESSION time_zone = '+00:00'");
    return $pdo;
  }
}