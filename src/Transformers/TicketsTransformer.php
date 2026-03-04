<?php
declare(strict_types=1);

final class TicketsTransformer {
  public static function normalize(array $row): array {
    $status = $row['status_chamado'] ?? '';
    $isAberto = !in_array($status, ['Solucionado', 'Fechado']);

    // 1. Faixa de Dias Sem Atualização
    $diasUpd = $row['dias_sem_atualizacao'] ?? null;
    if ($isAberto && $diasUpd !== null) {
      $row['faixa_sem_atualizacao'] = self::getFaixaSemAtualizacao((int)$diasUpd);
    } else {
      $row['faixa_sem_atualizacao'] = 'N/A';
    }

    // 2. Faixa de Aging (Tempo de Vida)
    $agingMin = $row['aging_minutos'] ?? null;
    if ($isAberto && $agingMin !== null) {
      $row['faixa_aging'] = self::getFaixaAging((float)$agingMin);
    } else {
      $row['faixa_aging'] = 'N/A';
    }

    return $row;
  }

  /**
   * Regra:
   * - Até 1 dia (24h)
   * - Até 3 dias
   * - Até 7 dias
   * - Maior que 7 dias
   */
  public static function getFaixaSemAtualizacao(int $dias): string {
    if ($dias <= 1) return 'Até 1 dia';
    if ($dias <= 3) return 'Até 3 dias';
    if ($dias <= 7) return 'Até 7 dias';
    return 'Maior que 7 dias';
  }

  /**
   * Regra:
   * - 0 a 3 dias (4320 min)
   * - Até 5 dias (7200 min)
   * - Até 10 dias (14400 min)
   * - Até 15 dias (21600 min)
   * - Até 30 dias (43200 min)
   * - Maior que 30 dias
   */
  public static function getFaixaAging(float $minutos): string {
    $dias = $minutos / 1440;
    if ($dias <= 3) return '0 a 3 dias';
    if ($dias <= 5) return 'Até 5 dias';
    if ($dias <= 10) return 'Até 10 dias';
    if ($dias <= 15) return 'Até 15 dias';
    if ($dias <= 30) return 'Até 30 dias';
    return 'Maior que 30 dias';
  }
}