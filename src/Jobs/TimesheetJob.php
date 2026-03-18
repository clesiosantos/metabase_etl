<?php
declare(strict_types=1);

final class TimesheetJob {
  public static function run(PDO $src, PDO $dst, Logger $log, string $mode, int $batchSize): void {
    $entity = 'timesheet';
    $startedAt = microtime(true);
    
    $runId = EtlRun::start($dst, $entity, $mode, 0, $batchSize, ['metabase_timesheet']);
    $log->info("TimesheetJob: início", ['run_id' => $runId, 'mode' => $mode, 'batch' => $batchSize]);

    try {
      $lastUtc = ($mode === 'full') ? '1970-01-01 00:00:00' : (Checkpoint::get($dst, $entity) ?? '1970-01-01 00:00:00');
      $log->info("TimesheetJob: buscando IDs alterados desde $lastUtc", ['run_id' => $runId]);
      
      // 1. Processar Tarefas Padrão (Tickets, Changes, Problems)
      $tasks = TimesheetExtractor::fetchChangedTaskIds($src, $lastUtc);
      $totalTasks = count($tasks);
      
      // 2. Processar Formcreator ID 142
      $formIds = TimesheetExtractor::fetchChangedForm142Ids($src, $lastUtc);
      $totalForms = count($formIds);

      $totalToProcess = $totalTasks + $totalForms;
      EtlRun::setSelected($dst, $runId, $totalToProcess);
      $log->info("TimesheetJob: IDs selecionados", ['run_id' => $runId, 'tarefas' => $totalTasks, 'forms_142' => $totalForms]);

      if ($totalToProcess === 0) {
        EtlRun::finishSuccess($dst, $runId, [], 'Nada a processar');
        $log->info("TimesheetJob: fim (nada a processar)", ['run_id' => $runId]);
        return;
      }

      $upsert = TimesheetLoader::upsertStatement($dst);

      // Executar carga de Tarefas Padrão
      if ($totalTasks > 0) {
        $chunks = array_chunk($tasks, $batchSize);
        foreach ($chunks as $i => $chunk) {
          $log->info("TimesheetJob: processando lote de tarefas", ['run_id' => $runId, 'lote' => $i + 1, 'tamanho' => count($chunk)]);
          $st = TimesheetExtractor::fetchTaskDetails($src, $chunk);
          $dst->beginTransaction();
          $count = 0;
          while ($row = $st->fetch(PDO::FETCH_ASSOC)) {
            $upsert->execute(self::bindRow($row));
            $count++;
          }
          $dst->commit();
          EtlRun::addUpserted($dst, $runId, $count);
        }
      }

      // Executar carga de Formulários 142
      if ($totalForms > 0) {
        $chunks = array_chunk($formIds, $batchSize);
        foreach ($chunks as $i => $chunk) {
          $log->info("TimesheetJob: processando lote de forms 142", ['run_id' => $runId, 'lote' => $i + 1, 'tamanho' => count($chunk)]);
          $st = TimesheetExtractor::fetchForm142Details($src, $chunk);
          $dst->beginTransaction();
          $count = 0;
          while ($row = $st->fetch(PDO::FETCH_ASSOC)) {
            $upsert->execute(self::bindRow($row));
            $count++;
          }
          $dst->commit();
          EtlRun::addUpserted($dst, $runId, $count);
        }
      }

      Checkpoint::set($dst, $entity, gmdate('Y-m-d H:i:s'));
      
      $elapsed = round(microtime(true) - $startedAt, 3);
      EtlRun::finishSuccess($dst, $runId, [], "Carga finalizada em {$elapsed}s");
      $log->info("TimesheetJob: concluído", ['run_id' => $runId, 'elapsed_sec' => $elapsed]);

    } catch (Throwable $e) {
      if ($dst->inTransaction()) $dst->rollBack();
      $log->error("TimesheetJob: falhou", ['run_id' => $runId ?? null, 'message' => $e->getMessage()]);
      if (isset($runId)) EtlRun::finishFailed($dst, $runId, $e->getMessage());
      throw $e;
    }
  }

  private static function bindRow(array $row): array {
    return [
      ':id_tarefa' => $row['id_tarefa'],
      ':id_tarefa_original' => $row['id_tarefa_original'],
      ':id_tarefa_formatado' => $row['id_tarefa_formatado'],
      ':tipo_ticket' => $row['tipo_ticket'],
      ':id_pai' => $row['id_pai'],
      ':data_abertura_pai' => $row['data_abertura_pai'],
      ':data_fechamento_pai' => $row['data_fechamento_pai'],
      ':cliente' => $row['cliente'],
      ':grupo_solucionador' => $row['grupo_solucionador'],
      ':tecnico' => $row['tecnico'],
      ':data_lancamento' => $row['data_lancamento'],
      ':data_criacao_tarefa' => $row['data_criacao_tarefa'],
      ':horas' => $row['horas'],
      ':tipo_hora' => $row['tipo_hora'],
      ':data_carga' => $row['data_carga'] ?? gmdate('Y-m-d H:i:s'),
    ];
  }
}