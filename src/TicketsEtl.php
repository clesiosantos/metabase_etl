<?php
declare(strict_types=1);

final class TicketsEtl {
  public static function run(PDO $src, PDO $dst, Logger $log, array $cfg, string $mode = 'incremental'): void {
    // Lock (se existir / se você já usa)
    if (class_exists('Lock')) {
      Lock::acquire($dst, 'etl_glpi_metabase_tickets', 10);
    }

    try {
      TicketsJob::run($src, $dst, $log, $cfg, $mode);
    } finally {
      if (class_exists('Lock')) {
        Lock::release($dst, 'etl_glpi_metabase_tickets');
      }
    }
  }
}