<?php
final class Config {
  public static function loadEnv(string $path): void {
    if (!is_file($path)) {
      throw new RuntimeException("Arquivo .env não encontrado em: {$path}");
    }
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
      $line = trim($line);
      if ($line === '' || str_starts_with($line, '#')) continue;
      [$k, $v] = array_pad(explode('=', $line, 2), 2, '');
      $k = trim($k);
      $v = trim($v);
      if ($k !== '') {
        $_ENV[$k] = $v;
      }
    }
  }

  public static function get(string $key, ?string $default = null): string {
    $v = $_ENV[$key] ?? getenv($key);
    if ($v === false || $v === null || $v === '') {
      if ($default !== null) return $default;
      throw new RuntimeException("Variável de ambiente não definida: {$key}");
    }
    return (string)$v;
  }

  public static function asArray(): array {
    return [
      'source' => [
        'host' => self::get('GLPI_HOST'),
        'port' => (int)self::get('GLPI_PORT', '3306'),
        'db'   => self::get('GLPI_DB', 'glpi'),
        'user' => self::get('GLPI_USER'),
        'pass' => self::get('GLPI_PASS'),
        'charset' => 'utf8mb4',
      ],
      'target' => [
        'host' => self::get('DW_HOST'),
        'port' => (int)self::get('DW_PORT', '3306'),
        'db'   => self::get('DW_DB', 'dw_glpi'),
        'user' => self::get('DW_USER'),
        'pass' => self::get('DW_PASS'),
        'charset' => 'utf8mb4',
      ],
      'etl' => [
        'window_full_days' => (int)self::get('ETL_WINDOW_FULL_DAYS', '15'),
        'batch_size' => (int)self::get('ETL_BATCH_SIZE', '1000'),
        'lock_name' => self::get('ETL_LOCK_NAME', 'etl_glpi_dw_lock'),
        'timezone' => self::get('ETL_TIMEZONE', 'America/Sao_Paulo'),
        'log_file' => self::get('ETL_LOG_FILE', __DIR__ . '/../logs/etl.log'),
      ],
    ];
  }
}