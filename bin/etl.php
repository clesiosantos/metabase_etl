<?php
declare(strict_types=1);

date_default_timezone_set('UTC');

/**
 * Carrega config de forma robusta:
 * - config/config.php pode retornar array (return [...])
 * - ou pode definir $CFG = [...]
 */
$cfgFromReturn = require __DIR__ . '/../config/config.php';

$CFG = null;
if (is_array($cfgFromReturn)) {
  $CFG = $cfgFromReturn;
} elseif (isset($GLOBALS['CFG']) && is_array($GLOBALS['CFG'])) {
  $CFG = $GLOBALS['CFG'];
} elseif (isset($CFG) && is_array($CFG)) {
  // caso o config defina $CFG diretamente no escopo
} else {
  throw new RuntimeException("config/config.php deve retornar um array ou definir \$CFG (array).");
}

if (!is_array($CFG)) {
  throw new RuntimeException("Config inválida: \$CFG não é array.");
}

// Core
require_once __DIR__ . '/../src/Db.php';
require_once __DIR__ . '/../src/Logger.php';
require_once __DIR__ . '/../src/Lock.php';
require_once __DIR__ . '/../src/Checkpoint.php';
require_once __DIR__ . '/../src/EtlRun.php';
require_once __DIR__ . '/../src/EtlError.php';
require_once __DIR__ . '/../src/Validator.php';

// Tickets
require_once __DIR__ . '/../src/Extractors/TicketsExtractor.php';
require_once __DIR__ . '/../src/Transformers/TicketsTransformer.php';
require_once __DIR__ . '/../src/Loaders/TicketsLoader.php';

// Tags (mantém seu padrão existente no tree)
require_once __DIR__ . '/../src/Extractors/TagsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TagsLoader.php';
require_once __DIR__ . '/../src/Jobs/TagsJobs.php';

// Jobs / Orquestração
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

/**
 * Espera config no formato:
 * $CFG['glpi'] = [... cfg PDO ...]
 * $CFG['dw']   = [... cfg PDO ...]
 * $CFG['etl']  = [... parâmetros ...]
 */
if (!isset($CFG['glpi']) || !is_array($CFG['glpi'])) {
  throw new RuntimeException("Config faltando: \$CFG['glpi'] (array).");
}
if (!isset($CFG['dw']) || !is_array($CFG['dw'])) {
  throw new RuntimeException("Config faltando: \$CFG['dw'] (array).");
}
if (!isset($CFG['etl']) || !is_array($CFG['etl'])) {
  // não é fatal se você não usa, mas TicketsJob usa. Então exigimos.
  throw new RuntimeException("Config faltando: \$CFG['etl'] (array).");
}

$src = Db::pdo($CFG['glpi']);
$dst = Db::pdo($CFG['dw']);

switch ($entity) {
  case 'tickets':
    TicketsEtl::run($src, $dst, $log, $CFG, $mode);
    break;

  default:
    usage();
    exit(1);
}