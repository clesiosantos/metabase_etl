<?php
declare(strict_types=1);

final class BacklogLoader {
  /**
   * Garante que as tabelas de backlog existam no banco de destino.
   */
  public static function createTables(PDO $dst): void {
    $sqlTickets = "
      CREATE TABLE IF NOT EXISTS history_tickets_backlog (
          chamado_id INT,
          data_abertura DATETIME,
          data_coleta DATE,
          PRIMARY KEY (chamado_id, data_coleta),
          INDEX idx_data_coleta (data_coleta)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";

    $sqlProblems = "
      CREATE TABLE IF NOT EXISTS history_problems_backlog (
          problem_id INT,
          data_abertura DATETIME,
          data_coleta DATE,
          PRIMARY KEY (problem_id, data_coleta),
          INDEX idx_data_coleta (data_coleta)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";

    $dst->exec($sqlTickets);
    $dst->exec($sqlProblems);
  }

  /**
   * Remove o snapshot de uma data específica para garantir idempotência.
   */
  public static function deleteSnapshot(PDO $dst, string $date, string $type): void {
    $table = ($type === 'tickets') ? 'history_tickets_backlog' : 'history_problems_backlog';
    $col = ($type === 'tickets') ? 'chamado_id' : 'problem_id';

    $sql = "DELETE FROM $table WHERE data_coleta = ?";
    $st = $dst->prepare($sql);
    $st->execute([$date]);
  }

  /**
   * Insere em lote os registros de backlog de tickets.
   */
  public static function insertTicketsSnapshot(PDO $dst, array $rows): int {
    if (!$rows) {
      return 0;
    }

    $sql = "
      INSERT INTO history_tickets_backlog (chamado_id, data_abertura, data_coleta)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE
        data_abertura = VALUES(data_abertura)
    ";
    $st = $dst->prepare($sql);

    $count = 0;
    foreach ($rows as $row) {
      $st->execute([
        $row['chamado_id'],
        $row['data_abertura'],
        $row['data_coleta']
      ]);
      $count++;
    }

    return $count;
  }

  /**
   * Insere em lote os registros de backlog de problemas.
   */
  public static function insertProblemsSnapshot(PDO $dst, array $rows): int {
    if (!$rows) {
      return 0;
    }

    $sql = "
      INSERT INTO history_problems_backlog (problem_id, data_abertura, data_coleta)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE
        data_abertura = VALUES(data_abertura)
    ";
    $st = $dst->prepare($sql);

    $count = 0;
    foreach ($rows as $row) {
      $st->execute([
        $row['problem_id'],
        $row['data_abertura'],
        $row['data_coleta']
      ]);
      $count++;
    }

    return $count;
  }
}
