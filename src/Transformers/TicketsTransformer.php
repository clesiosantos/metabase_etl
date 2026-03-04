<?php
declare(strict_types=1);

final class TicketsTransformer {
  public static function normalize(array $row): array {
    // Cálculo de dias sem atualização (se não vier do SQL)
    $dias = $row['dias_sem_atualizacao'] ?? null;
    
    if ($dias !== null) {
      $row['faixa_sem_atualizacao'] = self::getFaixaDias((int)$dias);
    } else {
      $row['faixa_sem_atualizacao'] = 'N/A';
    }

    return $row;
  }

  public static function getFaixaDias(int $dias): string {
    if ($dias <= 1) return '0 a 1 dia';
    if ($dias <= 3) return '2 a 3 dias';
    if ($dias <= 7) return '4 a 7 dias';
    if ($dias <= 15) return '8 a 15 dias';
    return '+15 dias';
  }
}