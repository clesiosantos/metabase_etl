<?php
/**
 * Data: 26/02/2026
 * Versão: 1.0.1
 * Autor: 3P Systems — www.3psystems.com.br
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
require_once __DIR__ . '/../src/Lock.php';
require_once __DIR__ . '/../src/Checkpoint.php';
require_once __DIR__ . '/../src/EtlRun.php';
require_once __DIR__ . '/../src/EtlError.php';
require_once __DIR__ . '/../src/Validator.php';

// 3. Carregar Componentes de Tickets (Ordem: Extractor -> Transformer -> Loader)
require_once __DIR__ . '/../src/Extractors/TicketsExtractor.php';
require_once __DIR__ . '/../src/Transformers/TicketsTransformer.php';
require_once __DIR__ . '/../src/Loaders/TicketsLoader.php';

// 4. Carregar Componentes de Tags
require_once __DIR__ . '/../src/Extractors/TagsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TagsLoader.php';
require_once __DIR__ . '/../src/Jobs/TagsJobs.php';

// 5. Carregar Orquestradores (Jobs e ETL)
require_once __DIR__ . '/../src/Jobs/TicketsJob.php';
require_once __DIR__ . '/../src/TicketsEtl.php';

function usage(): void {
  fwrite(STDERR, "Uso:\n  php bin/etl.php tickets [--full]\n");
}

$args = $argv;
array_shift($args);

$entity = $args[0] ?? null;
$mode = in_array('--full', $args, true) ? 'full' : 'incremental';

if (!$entity) {
  usage();
  exit(1);
}

$log = new Logger($CFG['etl']['log_file']);

// Conexões PDO via Db::pdo()
$src = Db::pdo($CFG['source']);
$dst = Db::pdo($CFG['target']);

switch ($entity) {
  case 'tickets':
    TicketsEtl::run($src, $dst, $log, $CFG, $mode);
    break;
  default:
    usage();
    exit(1);
}