<?php
declare(strict_types=1);

final class BacklogJob {
  /**
   * Executa a captura do snapshot de backlog para uma data específica.
   * 
   * @param PDO $dst Conexão com o banco de destino (DW)
   * @param string $date Data de referência no formato 'Y-m-d'
   * @param Logger|null $log Logger para registro de eventos
   */
  public static function runSnapshot(PDO $dst, string $date, ?Logger $log = null): array {
    // Garante que as tabelas existam
    BacklogLoader::createTables($dst);

    $dateEnd = $date . ' 23:59:59';

    if ($log) {
      $log->info("BacklogJob: Iniciando snapshot para a data $date", ['date_end' => $dateEnd]);
    }

    // 1. Processar Tickets (Incidentes e Requisições)
    $sqlTickets = "
      SELECT chamado AS chamado_id, data_criacao AS data_abertura
      FROM metabase_tickets
      WHERE data_criacao <= ?
        AND (data_solucao IS NULL OR data_solucao > ?)
        AND (data_fechamento IS NULL OR data_fechamento > ?)
    ";
    $stTickets = $dst->prepare($sqlTickets);
    $stTickets->execute([$dateEnd, $dateEnd, $dateEnd]);
    $tickets = $stTickets->fetchAll(PDO::FETCH_ASSOC);

    $ticketRows = [];
    foreach ($tickets as $t) {
      $ticketRows[] = [
        'chamado_id' => (int)$t['chamado_id'],
        'data_abertura' => $t['data_abertura'],
        'data_coleta' => $date
      ];
    }

    // 2. Processar Problemas
    $sqlProblems = "
      SELECT chamado AS problem_id, data_criacao AS data_abertura
      FROM metabase_problems
      WHERE data_criacao <= ?
        AND (data_solucao IS NULL OR data_solucao > ?)
        AND (data_fechamento IS NULL OR data_fechamento > ?)
    ";
    $stProblems = $dst->prepare($sqlProblems);
    $stProblems->execute([$dateEnd, $dateEnd, $dateEnd]);
    $problems = $stProblems->fetchAll(PDO::FETCH_ASSOC);

    $problemRows = [];
    foreach ($problems as $p) {
      $problemRows[] = [
        'problem_id' => (int)$p['problem_id'],
        'data_abertura' => $p['data_abertura'],
        'data_coleta' => $date
      ];
    }

    // 3. Persistir no banco usando transação para garantir consistência
    $dst->beginTransaction();
    try {
      // Deleta snapshots anteriores da mesma data para garantir idempotência
      BacklogLoader::deleteSnapshot($dst, $date, 'tickets');
      BacklogLoader::deleteSnapshot($dst, $date, 'problems');

      // Insere novos snapshots
      $insertedTickets = BacklogLoader::insertTicketsSnapshot($dst, $ticketRows);
      $insertedProblems = BacklogLoader::insertProblemsSnapshot($dst, $problemRows);

      $dst->commit();

      if ($log) {
        $log->info("BacklogJob: Snapshot finalizado com sucesso para a data $date", [
          'tickets_backlog_count' => $insertedTickets,
          'problems_backlog_count' => $insertedProblems
        ]);
      }

      return [
        'date' => $date,
        'tickets_count' => $insertedTickets,
        'problems_count' => $insertedProblems
      ];
    } catch (Throwable $e) {
      $dst->rollBack();
      if ($log) {
        $log->error("BacklogJob: Erro ao salvar snapshot para a data $date: " . $e->getMessage());
      }
      throw $e;
    }
  }

  /**
   * Executa o reprocessamento/backfill histórico para um intervalo de datas.
   * 
   * @param PDO $dst Conexão com o banco de destino (DW)
   * @param string $startDate Data de início no formato 'Y-m-d'
   * @param string $endDate Data de fim no formato 'Y-m-d'
   * @param Logger|null $log Logger para registro de eventos
   */
  public static function runBackfill(PDO $dst, string $startDate, string $endDate, ?Logger $log = null): array {
    if ($log) {
      $log->info("BacklogJob: Iniciando backfill histórico de backlog", [
        'start_date' => $startDate,
        'end_date' => $endDate
      ]);
    }

    $start = new DateTime($startDate);
    $end = new DateTime($endDate);
    $interval = new DateInterval('P1D');
    $period = new DatePeriod($start, $interval, $end->modify('+1 day'));

    $results = [];
    foreach ($period as $dt) {
      $currentDate = $dt->format('Y-m-d');
      $res = self::runSnapshot($dst, $currentDate, $log);
      $results[] = $res;
    }

    if ($log) {
      $log->info("BacklogJob: Backfill histórico finalizado com sucesso", [
        'total_days' => count($results)
      ]);
    }

    return $results;
  }
}
