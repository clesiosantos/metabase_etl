<?php
declare(strict_types=1);

final class TicketsEtl {
  public static function run(PDO $src, PDO $dst, Logger $log, string $mode = 'incremental'): void {
    // Carrega config global do config/config.php (variáveis $ETL_CFG, etc.)
    // Se você já tem um array de config padronizado, adapte aqui.
    $cfg = self::loadCfg();

    // Se seu projeto usa lock, faça aqui
    if (class_exists('Lock')) {
      // Nome do lock pode ser o que você já usa no seu ambiente
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

  private static function loadCfg(): array {
    /**
     * Ajuste este método para o seu config/config.php.
     * O importante é: TicketsJob espera $cfg['etl']['batch_size'] e ['window_full_days'].
     */
    if (isset($GLOBALS['ETL_CFG']) && is_array($GLOBALS['ETL_CFG'])) {
      return $GLOBALS['ETL_CFG'];
    }

    // fallback seguro: defaults
    return [
      'etl' => [
        'batch_size' => 1000,
        'window_full_days' => 15
      ]
    ];
  }
}