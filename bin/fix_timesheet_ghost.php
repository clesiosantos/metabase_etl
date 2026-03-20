<?php
/**
 * Script de Correção: Remove tarefas manuais do DW para chamados Form 142
 * Uso: php bin/fix_timesheet_ghost.php 52292
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/config.php';
Config::loadEnv(__DIR__ . '/../config/.env');
$CFG = Config::asArray();
require_once __DIR__ . '/../src/Db.php';

$ticketId = $argv[1] ?? null;
if (!$ticketId) {
    die("Informe o ID do chamado. Ex: php bin/fix_timesheet_ghost.php 52292\n");
}

try {
    $dst = Db::pdo($CFG['target']);
    
    echo "--- Corrigindo Chamado #$ticketId no DW ---\n";
    
    // 1. Remove a tarefa manual que está "presa" com valor errado
    $st = $dst->prepare("DELETE FROM metabase_timesheet WHERE id_pai = ? AND tipo_ticket = 'Ticket'");
    $st->execute([$ticketId]);
    $deleted = $st->rowCount();
    
    echo "Sucesso: $deleted tarefa(s) manuais removidas do DW.\n";
    echo "Agora, execute o ETL para carregar as horas corretas via Form 142:\n";
    echo "php bin/etl.php timesheet\n";

} catch (Throwable $e) {
    echo "Erro: " . $e->getMessage() . "\n";
}