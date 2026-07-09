<?php
/**
 * Script CLI para gerenciamento e captura do histórico de backlog no DW.
 * 
 * Uso:
 *   - Capturar snapshot de hoje:
 *     php bin/backlog.php
 * 
 *   - Capturar snapshot de uma data específica:
 *     php bin/backlog.php --date=2026-02-26
 * 
 *   - Executar backfill histórico para um intervalo de datas:
 *     php bin/backlog.php --backfill --start=2026-01-01 --end=2026-02-26
 */

declare(strict_types=1);

date_default_timezone_set('UTC');

// 1. Carregar Configuração e Ambiente
require_once __DIR__ . '/../config/config.php';
Config::loadEnv(__DIR__ . '/../config/.env');
$CFG = Config::asArray();

// 2. Carregar Core e Utilitários
require_once __DIR__ . '/../src/Db.php';
require_once __DIR__ . '/../src/Logger.php';
require_once __DIR__ . '/../src/Loaders/BacklogLoader.php';
require_once __DIR__ . '/../src/Jobs/BacklogJob.php';

function usage(): void {
  fwrite(STDERR, "Uso:\n");
  fwrite(STDERR, "  - Capturar snapshot de hoje:\n");
  fwrite(STDERR, "    php bin/backlog.php\n\n");
  fwrite(STDERR, "  - Capturar snapshot de uma data específica:\n");
  fwrite(STDERR, "    php bin/backlog.php --date=YYYY-MM-DD\n\n");
  fwrite(STDERR, "  - Executar backfill histórico para um intervalo de datas:\n");
  fwrite(STDERR, "    php bin/backlog.php --backfill --start=YYYY-MM-DD --end=YYYY-MM-DD\n");
}

$args = $argv;
array_shift($args);

$log = new Logger($CFG['etl']['log_file']);
$dst = Db::pdo($CFG['target']);

// Parse de argumentos simples
$params = [];
foreach ($args as $arg) {
  if (str_starts_with($arg, '--')) {
    $parts = explode('=', substr($arg, 2), 2);
    $key = $parts[0];
    $val = $parts[1] ?? true;
    $params[$key] = $val;
  }
}

try {
  if (isset($params['backfill'])) {
    $start = $params['start'] ?? null;
    $end = $params['end'] ?? null;

    if (!$start || !$end) {
      fwrite(STDERR, "Erro: Parâmetros --start e --end são obrigatórios para backfill.\n");
      usage();
      exit(1);
    }

    echo "Iniciando backfill histórico de backlog de $start até $end...\n";
    $results = BacklogJob::runBackfill($dst, (string)$start, (string)$end, $log);
    echo "Backfill finalizado com sucesso! Processados " . count($results) . " dias.\n";
    foreach ($results as $res) {
      echo "  - {$res['date']}: {$res['tickets_count']} tickets, {$res['problems_count']} problemas no backlog.\n";
    }
  } else {
    $date = $params['date'] ?? gmdate('Y-m-d');
    echo "Iniciando captura de snapshot de backlog para a data $date...\n";
    $res = BacklogJob::runSnapshot($dst, (string)$date, $log);
    echo "Snapshot finalizado com sucesso!\n";
    echo "  - Tickets no backlog: {$res['tickets_count']}\n";
    echo "  - Problemas no backlog: {$res['problems_count']}\n";
  }
} catch (Throwable $e) {
  $log->error("Erro no script de backlog: " . $e->getMessage());
  fwrite(STDERR, "Erro: " . $e->getMessage() . "\n");
  exit(1);
}
