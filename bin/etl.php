<?php
/**
 * Data: 26/02/2026
 * Versão: 1.0.5
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

// 3. Carregar Componentes de Tickets
require_once __DIR__ . '/../src/Extractors/TicketsExtractor.php';
require_once __DIR__ . '/../src/Transformers/TicketsTransformer.php';
require_once __DIR__ . '/../src/Loaders/TicketsLoader.php';

// 4. Carregar Componentes de Changes
require_once __DIR__ . '/../src/Extractors/ChangesExtractor.php';
require_once __DIR__ . '/../src/Loaders/ChangesLoader.php';
require_once __DIR__ . '/../src/Jobs/ChangesJob.php';

// 5. Carregar Componentes de Problems
require_once __DIR__ . '/../src/Extractors/ProblemsExtractor.php';
require_once __DIR__ . '/../src/Loaders/ProblemsLoader.php';
require_once __DIR__ . '/../src/Jobs/ProblemsJob.php';

// 6. Carregar Componentes de Tags
require_once __DIR__ . '/../src/Extractors/TagsExtractor.php';
require_once __DIR__ . '/../src/Loaders/TagsLoader.php';
require_once __DIR__ . '/../src/Jobs/TagsJobs.php';

// 7. Carregar Componentes de Timesheet
require_once __DIR__ . '/../src/Extractors/TimesheetExtractor.php';
require_once __DIR__ . '/../src/Loaders/TimesheetLoader.php';
require_once __DIR__ . '/../src/Jobs/TimesheetJob.php';

// 8. Carregar Orquestradores
require_once __DIR__ . '/../src/Jobs/TicketsJob.php';
require_once __DIR__ . '/../src/TicketsEtl.php';

function usage(): void {
  fwrite(STDERR, "Uso:\n  php bin/etl.php <all|tickets|changes|problems|timesheet> [--full]\n");
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
$src = Db::pdo($CFG['source']);
$dst = Db::pdo($CFG['target']);

// Lista de entidades para o comando 'all'
$entities = ($entity === 'all') 
    ? ['tickets', 'changes', 'problems', 'timesheet'] 
    : [$entity];

foreach ($entities as $ent) {
    $log->info("Iniciando processamento da entidade: $ent", ['mode' => $mode]);
    
    try {
        switch ($ent) {
            case 'tickets':
                TicketsEtl::run($src, $dst, $log, $CFG, $mode);
                break;
            case 'changes':
                ChangesJob::run($src, $dst, $mode, $CFG['etl']['window_full_days'] ?? 15, $CFG['etl']['batch_size'] ?? 1000);
                break;
            case 'problems':
                ProblemsJob::run($src, $dst, $mode, $CFG['etl']['window_full_days'] ?? 15, $CFG['etl']['batch_size'] ?? 1000);
                break;
            case 'timesheet':
                TimesheetJob::run($src, $dst, $log, $mode, $CFG['etl']['batch_size'] ?? 1000);
                break;
            default:
                if ($entity !== 'all') {
                    usage();
                    exit(1);
                }
        }
        $log->info("Entidade $ent processada com sucesso.");
    } catch (Throwable $e) {
        $log->error("Erro ao processar entidade $ent: " . $e->getMessage());
        if ($entity !== 'all') exit(1);
    }
}