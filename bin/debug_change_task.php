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

    echo "--- Buscando Tarefas associadas à Change #$changeId ---\n";

    $sql = "
        SELECT 
            tk.id,
            tk.changes_id,
            tk.date AS data_criacao,
            tk.begin AS data_inicio,
            
            -- Lógica robusta: se YEAR for 0 ou nulo, usa a data de criação (tk.date)
            CASE 
              WHEN tk.begin IS NULL OR YEAR(tk.begin) = 0
              THEN tk.date 
              ELSE tk.begin 
            END AS data_lancamento_calculada,

            tk.end AS data_fim,
            tk.actiontime AS tempo_segundos,
            (tk.actiontime / 3600) AS horas,
            tk.users_id,
            COALESCE(NULLIF(TRIM(CONCAT(IFNULL(u.firstname,''),' ',IFNULL(u.realname,''))),''), u.name) AS tecnico,
            tk.taskcategories_id,
            tc.name AS categoria_tarefa,
            tk.content AS conteudo
        FROM glpi_changetasks tk
        LEFT JOIN glpi_users u ON u.id = tk.users_id
        LEFT JOIN glpi_taskcategories tc ON tc.id = tk.taskcategories_id
        WHERE tk.changes_id = ?
    ";

    $st = $src->prepare($sql);
    $st->execute([$changeId]);
    $tasks = $st->fetchAll(PDO::FETCH_ASSOC);

    if (empty($tasks)) {
        echo "Nenhuma tarefa encontrada para a Change #$changeId na tabela glpi_changetasks.\n";
        exit;
    }

    echo "Total de tarefas encontradas: " . count($tasks) . "\n\n";

    foreach ($tasks as $i => $task) {
        echo "--- Tarefa [" . ($i + 1) . "] ID: {$task['id']} ---\n";
        echo "Data Criação: {$task['data_criacao']}\n";
        echo "Data Início (GLPI): " . ($task['data_inicio'] ?: 'VAZIO') . "\n";
        echo ">>> DATA LANÇAMENTO (Calculada): {$task['data_lancamento_calculada']}\n";
        echo "Horas: " . round((float)$task['horas'], 4) . "\n";
        echo "Técnico: {$task['tecnico']}\n";
        echo "Categoria: {$task['categoria_tarefa']}\n";
        echo "--------------------------------------\n\n";
    }

} catch (Throwable $e) {
    echo "ERRO NO DEBUG: " . $e->getMessage() . "\n";
}