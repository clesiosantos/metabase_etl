<?php
final class TicketsTransformer {
  public static function normalize(array $row): array {
    // Aqui é “no-op” por enquanto; mantém o desenho para evoluir regra (ex.: período, recorrência etc.)
    return $row;
  }
}