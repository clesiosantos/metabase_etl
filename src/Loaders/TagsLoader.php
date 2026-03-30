<?php
declare(strict_types=1);

final class TagsLoader {
  public static function upsertDimTags(PDO $dst): PDOStatement {
    $sql = "
      INSERT INTO dim_tags (
        tag_id, entities_id, is_recursive, is_active, name, comment, color, type_menu, data_carga
      ) VALUES (
        :tag_id, :entities_id, :is_recursive, :is_active, :name, :comment, :color, :type_menu, :data_carga
      )
      ON DUPLICATE KEY UPDATE
        entities_id=VALUES(entities_id),
        is_recursive=VALUES(is_recursive),
        is_active=VALUES(is_active),
        name=VALUES(name),
        comment=VALUES(comment),
        color=VALUES(color),
        type_menu=VALUES(type_menu),
        data_carga=VALUES(data_carga)
    ";
    return $dst->prepare($sql);
  }

  public static function upsertBridgeTicketTags(PDO $dst): PDOStatement {
    $sql = "
      INSERT INTO bridge_ticket_tags (ticket_id, tag_id, data_carga)
      VALUES (:ticket_id, :tag_id, :data_carga)
      ON DUPLICATE KEY UPDATE
        data_carga=VALUES(data_carga)
    ";
    return $dst->prepare($sql);
  }

  public static function upsertBridgeChangeTags(PDO $dst): PDOStatement {
    $sql = "
      INSERT INTO bridge_change_tags (change_id, tag_id, data_carga)
      VALUES (:change_id, :tag_id, :data_carga)
      ON DUPLICATE KEY UPDATE
        data_carga=VALUES(data_carga)
    ";
    return $dst->prepare($sql);
  }

  public static function upsertBridgeProblemTags(PDO $dst): PDOStatement {
    $sql = "
      INSERT INTO bridge_problem_tags (problem_id, tag_id, data_carga)
      VALUES (:problem_id, :tag_id, :data_carga)
      ON DUPLICATE KEY UPDATE
        data_carga=VALUES(data_carga)
    ";
    return $dst->prepare($sql);
  }

  public static function deleteTicketLinks(PDO $dst, array $ticketIds): void {
    if (!$ticketIds) {
      return;
    }

    $placeholders = implode(',', array_fill(0, count($ticketIds), '?'));
    $sql = "DELETE FROM bridge_ticket_tags WHERE ticket_id IN ($placeholders)";
    $st = $dst->prepare($sql);
    $st->execute(array_values($ticketIds));
  }

  public static function deleteChangeLinks(PDO $dst, array $changeIds): void {
    if (!$changeIds) {
      return;
    }

    $placeholders = implode(',', array_fill(0, count($changeIds), '?'));
    $sql = "DELETE FROM bridge_change_tags WHERE change_id IN ($placeholders)";
    $st = $dst->prepare($sql);
    $st->execute(array_values($changeIds));
  }

  public static function deleteProblemLinks(PDO $dst, array $problemIds): void {
    if (!$problemIds) {
      return;
    }

    $placeholders = implode(',', array_fill(0, count($problemIds), '?'));
    $sql = "DELETE FROM bridge_problem_tags WHERE problem_id IN ($placeholders)";
    $st = $dst->prepare($sql);
    $st->execute(array_values($problemIds));
  }

  public static function pruneBridgeLinks(PDO $dst, string $itemtype, string $loadTimestamp): int {
    $table = match ($itemtype) {
      'Ticket' => 'bridge_ticket_tags',
      'Change' => 'bridge_change_tags',
      'Problem' => 'bridge_problem_tags',
      default => throw new InvalidArgumentException("Itemtype inválido: $itemtype"),
    };
    $sql = "DELETE FROM $table WHERE data_carga < ?";
    $st = $dst->prepare($sql);
    $st->execute([$loadTimestamp]);
    return $st->rowCount();
  }
}