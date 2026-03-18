<?php
/**
 * Script de Debug: Análise da Change 786
 * Data: 26/02/2026
 */

declare(strict_types=1);

date_default_timezone_set('UTC');

require_once __DIR__ . '/../config/config.php';
Config::loadEnv(__DIR__ . '/../config/.env');
$CFG = Config::asArray();

require_once __DIR__ . '/../src/Db.php';
require_once __DIR__ . '/../src/Extractors/ChangesExtractor.php';

try {
    $src = Db::pdo($CFG['source']);
    $id = 786;

    echo "--- Iniciando Debug da Change #$id ---\n";

    // Simula a chamada que o Job faz
    $st = ChangesExtractor::fetchDetailsByIds($src, [$id]);
    $row = $st->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        echo "ERRO: Change #$id não encontrada no GLPI (ou is_deleted = 1).\n";
        exit(1);
    }

    echo "\n[DADOS BRUTOS DO EXTRACTOR]\n";
    print_r($row);

    echo "\n--- Análise de Campos Chave ---\n";
    echo "Título: " . ($row['titulo_chamado'] ?? 'N/A') . "\n";
    echo "Status: " . ($row['status_chamado'] ?? 'N/A') . "\n";
    echo "Classificação: " . ($row['classificacao'] ?? 'N/A') . "\n";
    echo "Início Mudança: " . ($row['data_inicio_mudanca'] ?? 'N/A') . "\n";
    echo "Fim Mudança: " . ($row['data_fim_mudanca'] ?? 'N/A') . "\n";
    echo "Grupo Solucionador: " . ($row['grupo_solucionador'] ?? 'N/A') . "\n";
    echo "Tags: " . ($row['tags'] ?? 'N/A') . "\n";

} catch (Throwable $e) {
    echo "ERRO NO DEBUG: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
}