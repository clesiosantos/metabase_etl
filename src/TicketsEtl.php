<?php
declare(strict_types=1);

final class TicketsEtl {
  public static function run(PDO $src, PDO $dst, Logger $log, array $cfg, string $mode = 'incremental'): void {
    $lockName = $cfg['etl']['lock_name'] ?? 'etl_glpi_dw_lock';

    if (class_exists('Lock')) {
      Lock::acquire($dst, $lockName, 10);
    }

    try {
      TicketsJob::run($src, $dst, $log, $cfg, $mode);
    } finally {
      if (class_exists('Lock')) {
        Lock::release($dst, $lockName);
      }
    }
  }
}