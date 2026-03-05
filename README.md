# ETL GLPI → DW (MySQL) → Metabase

... (mantém o conteúdo anterior) ...

### 15.4 Dicionário de dados (campos “novos” adicionados nesta fase)

Campos novos (catálogo):
- `categoria`
- `subcategoria`
- `servico`

Campos novos (solução):
- `tipo_solucao`: Nome completo do modelo de solução (ex: `Chamado::Cancelado`).
- `disciplina_solucao`: Primeira parte da solução (ex: `Chamado`).
- `modelo_solucao`: Segunda parte da solução (ex: `Cancelado`).

Campos novos (grupo):
- `grupo_solucionador_nome`
- `tipo_contrato`
- `grupo_solucao`
- `tipo_atividade`

... (mantém o restante do arquivo) ...