<?php
// bin/etl.php

date_default_timezone_set('UTC');

require_once __DIR__ . '/../src/Config.php';
require_once __DIR__ . '/../src/Logger.php';
require_once __DIR__ . '/../src/Db.php';

// Auditoria ETL
require_once __DIR__ . '/../src/EtlRun.php';
require_once __DIR__ . '/../src/EtlError.php';
require_once __DIR__ . '/../src/Checkpoint.php';
require_once __DIR__ . '/../src/Validator.php';

// Tickets
require_once __DIR__ . '/../src/Extractors/TicketsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TicketsLoader.php';
require_once __DIR__ . '/../src/Transformers/TicketsTransformer.php';

// TAGS (CRÍTICO: deve estar antes de Jobs que chamam TagsJob)
require_once __DIR__ . '/../src/Extractors/TagsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TagsLoader.php';
require_once __DIR__ . '/../src/Jobs/TagsJob.php';

// Jobs
require_once __DIR__ . '/../src/Jobs/TicketsJob.php';

function usage(): void {
  $msg = "Uso:\n"
    . "  php bin/etl.php tickets [--full]\n";
  fwrite(STDERR, $msg);
}

$args = $argv;
array_shift($args);

$entity = $args[0] ?? null;
$mode = in_array('--full', $args, true) ? 'full' : 'incremental';

if (!$entity) {
  usage();
  exit(1);
}

$cfg = Config::load(__DIR__ . '/../config/config.php');
$log = new Logger();

$src = Db::connect($cfg['glpi']);   // conexão origem
$dst = Db::connect($cfg['dw']);     // conexão dw_glpi

switch ($entity) {
  case 'tickets':
    TicketsJob::run($src, $dst, $log, $cfg, $mode);
    break;

  default:
    usage();
    exit(1);
}