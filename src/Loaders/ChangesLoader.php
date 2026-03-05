<?php
final class ChangesLoader {

  public static function upsertStatement(PDO $dst): PDOStatement {
    $sql = "
      INSERT INTO metabase_changes (
        chamado, titulo_chamado,
        data_criacao, data_solucao, data_fechamento, data_ultima_atualizacao, data_id,
        status_chamado, prioridade, urgencia, impacto,
        ttr_status, ttr_em_risco, limite_solucao,
        mttr_minutos, aging_minutos,
        servico_completo, categoria, subcategoria, servico, 
        tipo_solucao, disciplina_solucao, modelo_solucao,
        grupo_solucionador, grupo_solucionador_nome, id_grupo_solucionador,
        tipo_contrato, grupo_solucao, tipo_atividade,
        agente_solucionador, nome_solicitante,
        entidade_cliente, localizacao_fisica,
        tags,
        users_id_recipient, locations_id,
        data_carga
      ) VALUES (
        :chamado, :titulo_chamado,
        :data_criacao, :data_solucao, :data_fechamento, :data_ultima_atualizacao, :data_id,
        :status_chamado, :prioridade, :urgencia, :impacto,
        :ttr_status, :ttr_em_risco, :limite_solucao,
        :mttr_minutos, :aging_minutos,
        :servico_completo, :categoria, :subcategoria, :servico, 
        :tipo_solucao, :disciplina_solucao, :modelo_solucao,
        :grupo_solucionador, :grupo_solucionador_nome, :id_grupo_solucionador,
        :tipo_contrato, :grupo_solucao, :tipo_atividade,
        :agente_solucionador, :nome_solicitante,
        :entidade_cliente, :localizacao_fisica,
        :tags,
        :users_id_recipient, :locations_id,
        :data_carga
      )
      ON DUPLICATE KEY UPDATE
        titulo_chamado=VALUES(titulo_chamado),
        data_criacao=VALUES(data_criacao),
        data_solucao=VALUES(data_solucao),
        data_fechamento=VALUES(data_fechamento),
        data_ultima_atualizacao=VALUES(data_ultima_atualizacao),
        data_id=VALUES(data_id),
        status_chamado=VALUES(status_chamado),
        prioridade=VALUES(prioridade),
        urgencia=VALUES(urgencia),
        impacto=VALUES(impacto),
        ttr_status=VALUES(ttr_status),
        ttr_em_risco=VALUES(ttr_em_risco),
        limite_solucao=VALUES(limite_solucao),
        mttr_minutos=VALUES(mttr_minutos),
        aging_minutos=VALUES(aging_minutos),
        servico_completo=VALUES(servico_completo),
        categoria=VALUES(categoria),
        subcategoria=VALUES(subcategoria),
        servico=VALUES(servico),
        tipo_solucao=VALUES(tipo_solucao),
        disciplina_solucao=VALUES(disciplina_solucao),
        modelo_solucao=VALUES(modelo_solucao),
        grupo_solucionador=VALUES(grupo_solucionador),
        grupo_solucionador_nome=VALUES(grupo_solucionador_nome),
        id_grupo_solucionador=VALUES(id_grupo_solucionador),
        tipo_contrato=VALUES(tipo_contrato),
        grupo_solucao=VALUES(grupo_solucao),
        tipo_atividade=VALUES(tipo_atividade),
        agente_solucionador=VALUES(agente_solucionador),
        nome_solicitante=VALUES(nome_solicitante),
        entidade_cliente=VALUES(entidade_cliente),
        localizacao_fisica=VALUES(localizacao_fisica),
        tags=VALUES(tags),
        users_id_recipient=VALUES(users_id_recipient),
        locations_id=VALUES(locations_id),
        data_carga=VALUES(data_carga)
    ";
    return $dst->prepare($sql);
  }
}