<?php
/**
 * Script de Debug: Comparativo de Data de Lançamento
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
    $dst = Db::pdo($CFG['target']);
    $changeId = 786;

    echo "--- Debug Comparativo (Change #$changeId) ---\n\n";

    // 1. Busca como está no DW (Destino)
    $stDw = $dst->prepare("
        SELECT id_tarefa, data_lancamento, data_criacao_tarefa 
        FROM metabase_timesheet 
        WHERE tipo_ticket = 'Change' AND id_pai = ?
    ");
    $stDw->execute([$changeId]);
    $dwTasks = [];
    while ($r = $stDw->fetch(PDO::FETCH_ASSOC)) {
        $idOriginal = explode('_', $r['id_tarefa'])[1];
        $dwTasks[$idOriginal] = $r;
    }

    // 2. Busca na Origem (GLPI) e aplica a nova lógica
    $sqlSrc = "
        SELECT 
            tk.id,
            tk.date AS glpi_date,
            tk.begin AS glpi_begin,
            CASE 
              WHEN tk.begin IS NOT NULL AND YEAR(tk.begin) > 0
              THEN tk.begin 
              ELSE tk.date 
            END AS logic_result
        FROM glpi_changetasks tk
        WHERE tk.changes_id = ?
    ";

    $stSrc = $src->prepare($sqlSrc);
    $stSrc->execute([$changeId]);
    $glpiTasks = $stSrc->fetchAll(PDO::FETCH_ASSOC);

    if (empty($glpiTasks)) {
        echo "Nenhuma tarefa encontrada no GLPI para a Change #$changeId.\n";
        exit;
    }

    foreach ($glpiTasks as $task) {
        $id = (string)$task['id'];
        $dwVal = $dwTasks[$id]['data_lancamento'] ?? '!! NÃO ENCONTRADO NO DW !!';

        echo "[Tarefa ID: $id]\n";
        echo "  - NO BANCO DW (ANTES):      " . ($dwVal ?: '!! ESTÁ EM BRANCO !!') . "\n";
        echo "  - DADOS NO GLPI (BRUTOS):   date={$task['glpi_date']} | begin=" . ($task['glpi_begin'] ?: 'null') . "\n";
        echo "  - NOVA LÓGICA ETL (DEPOIS): {$task['logic_result']}\n";
        
        if ($dwVal === $task['logic_result']) {
            echo "  > STATUS: Já está sincronizado corretamente.\n";
        } else {
            echo "  > STATUS: PRECISA DE ATUALIZAÇÃO (Rode o ETL com --full).\n";
        }
        echo "--------------------------------------\n";
    }

} catch (Throwable $e) {
    echo "ERRO NO DEBUG: " . $e->getMessage() . "\n";
}