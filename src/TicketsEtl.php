<?php
/**
 * Data: 26/02/2026
 * Versão: 1.0.1
 * Autor: 3P Systems — www.3psystems.com.br
 */

declare(strict_types=1);

final class TicketsEtl {
  public static function run(PDO $src, PDO $dst, Logger $log, array $cfg, string $mode = 'incremental'): void {
    $lockName = $cfg['etl']['lock_name'] ?? 'etl_glpi_dw_lock';

    if (class_exists('Lock')) {
      Lock::acquire($dst, $lockName, 10);
    }

    try {
      // Executa o Job principal de Tickets
      TicketsJob::run($src, $dst, $log, $cfg, $mode);
    } finally {
      if (class_exists('Lock')) {
        Lock::release($dst, $lockName);
      }
    }
  }
}