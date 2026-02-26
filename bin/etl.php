<?php
declare(strict_types=1);

date_default_timezone_set('UTC');

require_once __DIR__ . '/../config/config.php';

require_once __DIR__ . '/../src/Db.php';
require_once __DIR__ . '/../src/Logger.php';
require_once __DIR__ . '/../src/Lock.php';
require_once __DIR__ . '/../src/Checkpoint.php';
require_once __DIR__ . '/../src/EtlRun.php';
require_once __DIR__ . '/../src/EtlError.php';
require_once __DIR__ . '/../src/Validator.php';

require_once __DIR__ . '/../src/Transformers/TicketsTransformer.php';

require_once __DIR__ . '/../src/Extractors/TicketsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TicketsLoader.php';

require_once __DIR__ . '/../src/Extractors/TagsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TagsLoader.php';
require_once __DIR__ . '/../src/Jobs/TagsJobs.php';

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

$log = new Logger(__DIR__ . '/../logs/etl.log');

try {
  $src = Db::connect($GLPI_DB);
  $dst = Db::connect($DW_DB);

  // lock global (opcional, se seu Lock.php já faz isso em TicketsEtl)
  // Lock::acquire($dst, 'etl_glpi_metabase', 10);

  switch ($entity) {
    case 'tickets':
      TicketsEtl::run($src, $dst, $log, $mode);
      break;
    default:
      usage();
      exit(1);
  }

  // Lock::release($dst, 'etl_glpi_metabase');
} catch (Throwable $e) {
  $log->error('ETL fatal', ['message' => $e->getMessage()]);
  throw $e;
}