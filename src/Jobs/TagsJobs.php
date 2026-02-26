<?php
final class TagsJob {
  public static function syncTags(PDO $src, PDO $dst, Logger $log, int $runId = 0): void {
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
      $log->info("TagsJob: dim_tags sincronizada", ['run_id' => $runId, 'count' => $count]);
    } catch (Throwable $e) {
      $dst->rollBack();
      $log->error("TagsJob: erro dim_tags", ['run_id' => $runId, 'message' => $e->getMessage()]);
      throw $e;
    }
  }

  public static function syncTicketTagLinks(PDO $src, PDO $dst, Logger $log, array $ticketIds, int $runId = 0): void {
    if (!$ticketIds) {
      $log->info("TagsJob: sem tickets para vínculos", ['run_id' => $runId]);
      return;
    }

    $dst->beginTransaction();
    try {
      // Recria vínculos para tickets impactados (remove vínculos antigos e insere os atuais)
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
      $log->info("TagsJob: bridge_ticket_tags sincronizada", [
        'run_id' => $runId,
        'tickets' => count($ticketIds),
        'links' => $count
      ]);
    } catch (Throwable $e) {
      $dst->rollBack();
      $log->error("TagsJob: erro bridge_ticket_tags", ['run_id' => $runId, 'message' => $e->getMessage()]);
      throw $e;
    }
  }
}