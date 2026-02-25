#!/usr/bin/env php
<?php
require_once __DIR__ . '/../config/config.php';
Config::loadEnv(__DIR__ . '/../config/.env');
$cfg = Config::asArray();

date_default_timezone_set($cfg['etl']['timezone']);

require_once __DIR__ . '/../src/Logger.php';
require_once __DIR__ . '/../src/Db.php';
require_once __DIR__ . '/../src/Lock.php';
require_once __DIR__ . '/../src/Checkpoint.php';

require_once __DIR__ . '/../src/EtlRun.php';
require_once __DIR__ . '/../src/EtlError.php';
require_once __DIR__ . '/../src/Validator.php';

require_once __DIR__ . '/../src/Extractors/TicketsExtractor.php';
require_once __DIR__ . '/../src/Transformers/TicketsTransformer.php';
require_once __DIR__ . '/../src/Loaders/TicketsLoader.php';
require_once __DIR__ . '/../src/Jobs/TicketsJob.php';

$argvAll = $argv;
array_shift($argvAll);

$entity = $argvAll[0] ?? 'tickets';
$mode = 'incremental';

foreach ($argvAll as $a) {
  if ($a === '--full') $mode = 'full';
}

$log = new Logger($cfg['etl']['log_file']);
$src = Db::pdo($cfg['source']);
$dst = Db::pdo($cfg['target']);

if (!Lock::acquire($dst, $cfg['etl']['lock_name'], 1)) {
  $log->info("Lock ativo, saindo");
  exit(0);
}

try {
  if ($entity === 'tickets') {
    TicketsJob::run($src, $dst, $log, $cfg, $mode);
  } else {
    $log->error("Entidade inválida", ['entity' => $entity]);
    exit(2);
  }
} finally {
  Lock::release($dst, $cfg['etl']['lock_name']);
}