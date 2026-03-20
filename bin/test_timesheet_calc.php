<?php
/**
 * Script de Teste: Validação de Cálculo de Horas (Form 142)
 * Uso: php bin/test_timesheet_calc.php 52292
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/config.php';
Config::loadEnv(__DIR__ . '/../config/.env');
$CFG = Config::asArray();
require_once __DIR__ . '/../src/Db.php';

$ticketId = $argv[1] ?? null;
if (!$ticketId) die("Informe o ID do chamado.\n");

try {
    $src = Db::pdo($CFG['source']);
    
    // Busca o ID da Resposta do Formulário vinculado ao ticket
    $st = $src->prepare("
        SELECT items_id 
        FROM glpi_items_tickets 
        WHERE tickets_id = ? AND itemtype = 'PluginFormcreatorFormAnswer'
    ");
    $st->execute([$ticketId]);
    $formAnswerId = $st->fetchColumn();

    if (!$formAnswerId) {
        die("Este chamado não possui vínculo com formulário (FormAnswer não encontrado).\n");
    }

    echo "--- Testando Cálculo para Ticket #$ticketId (FormAnswer #$formAnswerId) ---\n";

    // Simula a lógica do Extrator
    $sql = "
      SELECT 
        t.id as task_id, 
        t.actiontime, 
        (t.actiontime/3600) as horas_task,
        u.name as tecnico
      FROM glpi_tickettasks t
      LEFT JOIN glpi_users u ON u.id = t.users_id
      WHERE t.tickets_id = ?
    ";
    $stTasks = $src->prepare($sql);
    $stTasks->execute([$ticketId]);
    
    $totalHoras = 0;
    echo "\nTarefas encontradas no GLPI:\n";
    while ($task = $stTasks->fetch(PDO::FETCH_ASSOC)) {
        echo " - Tarefa #{$task['task_id']} | Técnico: {$task['tecnico']} | Horas: {$task['horas_task']}h\n";
        $totalHoras += $task['horas_task'];
    }

    echo "\n--------------------------------------\n";
    echo "RESULTADO FINAL QUE IRÁ PARA O DW: " . number_format($totalHoras, 2) . " horas\n";
    echo "--------------------------------------\n";

} catch (Throwable $e) {
    echo "Erro: " . $e->getMessage() . "\n";
}