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
      
      $tasks = TimesheetExtractor::fetchChangedTaskIds($src, $lastUtc);
      $formIds = TimesheetExtractor::fetchChangedForm142Ids($src, $lastUtc);

      $totalToProcess = count($tasks) + count($formIds);
      EtlRun::setSelected($dst, $runId, $totalToProcess);

      if ($totalToProcess === 0) {
        EtlRun::finishSuccess($dst, $runId, [], 'Nada a processar');
        return;
      }

      $upsert = TimesheetLoader::upsertStatement($dst);

      if (count($tasks) > 0) {
        $chunks = array_chunk($tasks, $batchSize);
        foreach ($chunks as $chunk) {
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

      if (count($formIds) > 0) {
        $chunks = array_chunk($formIds, $batchSize);
        foreach ($chunks as $chunk) {
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

    } catch (Throwable $e) {
      if ($dst->inTransaction()) $dst->rollBack();
      if (isset($runId)) EtlRun::finishFailed($dst, $runId, $e->getMessage());
      throw $e;
    }
  }

  private static function bindRow(array $row): array {
    return [
      ':id_tarefa' => $row['id_tarefa'],
      ':id_tarefa_original' => $row['id_tarefa_original'],
      ':id_resposta' => $row['id_resposta'],
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
      ':data_carga' => gmdate('Y-m-d H:i:s'),
    ];
  }
}