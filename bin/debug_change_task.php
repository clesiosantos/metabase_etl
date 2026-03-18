<?php
/**
 * Script de Debug: Análise de Tarefas da Change 786
 * Data: 26/02/2026
 */

declare(strict_types=1);

date_default_timezone_set('UTC');

require_once __DIR__ . '/../config/config.php';
Config::loadEnv(__DIR__ . '/../config/.env');
$CFG = Config::asArray();

require_once __DIR__ . '/../src/Db.php';

try {
    $src = Db::pdo($CFG['source']);
    $changeId = 786;

    echo "--- Debug de Tarefas (Change #$changeId) ---\n";
    echo "Comparativo de Dados Brutos vs Lógica do ETL\n\n";

    $sql = "
        SELECT 
            tk.id,
            tk.date AS raw_date,
            tk.begin AS raw_begin,
            
            -- Mesma lógica aplicada no TimesheetExtractor
            CASE 
              WHEN tk.begin IS NOT NULL AND YEAR(tk.begin) > 0
              THEN tk.begin 
              ELSE tk.date 
            END AS calculated_data_lancamento
        FROM glpi_changetasks tk
        WHERE tk.changes_id = ?
    ";

    $st = $src->prepare($sql);
    $st->execute([$changeId]);
    $tasks = $st->fetchAll(PDO::FETCH_ASSOC);

    if (empty($tasks)) {
        echo "Nenhuma tarefa encontrada.\n";
        exit;
    }

    foreach ($tasks as $i => $task) {
        echo "[Tarefa ID: {$task['id']}]\n";
        echo "  - ANTES (No GLPI):\n";
        echo "    * date:  " . ($task['raw_date'] ?: 'null') . "\n";
        echo "    * begin: " . ($task['raw_begin'] ?: 'null') . "\n";
        echo "  - DEPOIS (Lógica ETL):\n";
        echo "    * data_lancamento: " . ($task['calculated_data_lancamento'] ?: '!! VAZIO !!') . "\n";
        echo "--------------------------------------\n";
    }

} catch (Throwable $e) {
    echo "ERRO NO DEBUG: " . $e->getMessage() . "\n";
}