<?php
final class TagsExtractor {
  public static function fetchAllTags(PDO $src): PDOStatement {
    $sql = "
      SELECT
        id AS tag_id,
        entities_id,
        is_recursive,
        is_active,
        name,
        comment,
        color,
        type_menu
      FROM glpi_plugin_tag_tags
    ";
    return $src->query($sql);
  }

  public static function fetchTicketTagLinks(PDO $src, array $ticketIds): PDOStatement {
    if (!$ticketIds) {
      throw new RuntimeException("Lista de ticketIds vazia em fetchTicketTagLinks()");
    }

    $placeholders = implode(',', array_fill(0, count($ticketIds), '?'));

    $sql = "
      SELECT
        items_id AS ticket_id,
        plugin_tag_tags_id AS tag_id
      FROM glpi_plugin_tag_tagitems
      WHERE itemtype = 'Ticket'
        AND items_id IN ($placeholders)
    ";

    $st = $src->prepare($sql);
    $st->execute(array_values($ticketIds));
    return $st;
  }
}