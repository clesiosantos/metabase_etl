<?php
declare(strict_types=1);

final class TagsJobs {
  public static function syncDimTags(PDO $src, PDO $dst): int {
    $stTags = TagsExtractor::fetchAllTags($src);
    $upDim  = TagsLoader::upsertDimTags($dst);

    $dst->beginTransaction();
    try {
      $count = 0;
      $now = gmdate('Y-m-d H:i:s');

      while ($row = $stTags->fetch(PDO::FETCH_ASSOC)) {
        $row['data_carga'] = $now;
        $upDim->execute($row);
        $count++;
      }

      $dst->commit();
      return $count;
    } catch (Throwable $e) {
      $dst->rollBack();
      throw $e;
    }
  }

  public static function refreshTicketLinks(PDO $src, PDO $dst, array $ticketIds): int {
    if (!$ticketIds) {
      return 0;
    }

    $dst->beginTransaction();
    try {
      TagsLoader::deleteTicketLinks($dst, $ticketIds);

      $stLinks  = TagsExtractor::fetchTicketTagLinks($src, $ticketIds);
      $upBridge = TagsLoader::upsertBridgeTicketTags($dst);

      $count = 0;
      $now = gmdate('Y-m-d H:i:s');

      while ($row = $stLinks->fetch(PDO::FETCH_ASSOC)) {
        $upBridge->execute([
          ':ticket_id' => (int)$row['ticket_id'],
          ':tag_id' => (int)$row['tag_id'],
          ':data_carga' => $now
        ]);
        $count++;
      }

      $dst->commit();
      return $count;
    } catch (Throwable $e) {
      $dst->rollBack();
      throw $e;
    }
  }

  public static function refreshChangeLinks(PDO $src, PDO $dst, array $changeIds): int {
    if (!$changeIds) {
      return 0;
    }

    $dst->beginTransaction();
    try {
      TagsLoader::deleteChangeLinks($dst, $changeIds);

      $stLinks  = TagsExtractor::fetchChangeTagLinks($src, $changeIds);
      $upBridge = TagsLoader::upsertBridgeChangeTags($dst);

      $count = 0;
      $now = gmdate('Y-m-d H:i:s');

      while ($row = $stLinks->fetch(PDO::FETCH_ASSOC)) {
        $upBridge->execute([
          ':change_id' => (int)$row['change_id'],
          ':tag_id' => (int)$row['tag_id'],
          ':data_carga' => $now
        ]);
        $count++;
      }

      $dst->commit();
      return $count;
    } catch (Throwable $e) {
      $dst->rollBack();
      throw $e;
    }
  }
}