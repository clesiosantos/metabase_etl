<?php
declare(strict_types=1);

final class TimesheetLoader {
  public static function upsertStatement(PDO $dst): PDOStatement {
    $sql = "
      INSERT INTO metabase_timesheet (
        id_tarefa, tipo_ticket, id_pai, data_abertura_pai, data_fechamento_pai,
        cliente, grupo_solucionador, tecnico, data_lancamento, horas, tipo_hora, data_carga
      ) VALUES (
        :id_tarefa, :tipo_ticket, :id_pai, :data_abertura_pai, :data_fechamento_pai,
        :cliente, :grupo_solucionador, :tecnico, :data_lancamento, :horas, :tipo_hora, :data_carga
      )
      ON DUPLICATE KEY UPDATE
        tipo_ticket=VALUES(tipo_ticket),
        id_pai=VALUES(id_pai),
        data_abertura_pai=VALUES(data_abertura_pai),
        data_fechamento_pai=VALUES(data_fechamento_pai),
        cliente=VALUES(cliente),
        grupo_solucionador=VALUES(grupo_solucionador),
        tecnico=VALUES(tecnico),
        data_lancamento=VALUES(data_lancamento),
        horas=VALUES(horas),
        tipo_hora=VALUES(tipo_hora),
        data_carga=VALUES(data_carga)
    ";
    return $dst->prepare($sql);
  }
}