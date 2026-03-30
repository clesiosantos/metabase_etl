<?php
declare(strict_types=1);

final class TagsJobs {
  public static function syncDimTags(PDO $src, PDO $dst, string $loadTimestamp): int {
    $stTags = TagsExtractor::fetchAllTags($src);
    $upDim  = TagsLoader::upsertDimTags($dst);

    $dst->beginTransaction();
    try {
      $count = 0;

      while ($row = $stTags->fetch(PDO::FETCH_ASSOC)) {
        $row['data_carga'] = $loadTimestamp;
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

  public static function refreshTicketLinks(PDO $src, PDO $dst, array $ticketIds, string $loadTimestamp): int {
    if (!$ticketIds) {
      return 0;
    }

    $dst->beginTransaction();
    try {
      TagsLoader::deleteTicketLinks($dst, $ticketIds);

      $stLinks  = TagsExtractor::fetchTicketTagLinks($src, $ticketIds);
      $upBridge = TagsLoader::upsertBridgeTicketTags($dst);

      $count = 0;

      while ($row = $stLinks->fetch(PDO::FETCH_ASSOC)) {
        $upBridge->execute([
          ':ticket_id' => (int)$row['ticket_id'],
          ':tag_id' => (int)$row['tag_id'],
          ':data_carga' => $loadTimestamp
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

  public static function refreshChangeLinks(PDO $src, PDO $dst, array $changeIds, string $loadTimestamp): int {
    if (!$changeIds) {
      return 0;
    }

    $dst->beginTransaction();
    try {
      TagsLoader::deleteChangeLinks($dst, $changeIds);

      $stLinks  = TagsExtractor::fetchChangeTagLinks($src, $changeIds);
      $upBridge = TagsLoader::upsertBridgeChangeTags($dst);

      $count = 0;

      while ($row = $stLinks->fetch(PDO::FETCH_ASSOC)) {
        $upBridge->execute([
          ':change_id' => (int)$row['change_id'],
          ':tag_id' => (int)$row['tag_id'],
          ':data_carga' => $loadTimestamp
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

  public static function refreshProblemLinks(PDO $src, PDO $dst, array $problemIds, string $loadTimestamp): int {
    if (!$problemIds) {
      return 0;
    }

    $dst->beginTransaction();
    try {
      TagsLoader::deleteProblemLinks($dst, $problemIds);

      $stLinks  = TagsExtractor::fetchProblemTagLinks($src, $problemIds);
      $upBridge = TagsLoader::upsertBridgeProblemTags($dst);

      $count = 0;

      while ($row = $stLinks->fetch(PDO::FETCH_ASSOC)) {
        $upBridge->execute([
          ':problem_id' => (int)$row['problem_id'],
          ':tag_id' => (int)$row['tag_id'],
          ':data_carga' => $loadTimestamp
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
