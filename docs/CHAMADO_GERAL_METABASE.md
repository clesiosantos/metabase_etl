# Documentação: Dashboard Gestão a Vista - Aba Chamado Geral

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Chamado Geral**.

## 1. Regras de Negócio
- **Disponibilidade de Dados:** Todas as tags (incluindo `Ticket::Cancelado` e `Ticket::Duplicado`) estão disponíveis no DW.
- **Filtro Padrão:** Recomenda-se configurar o filtro `{{tipo_solucao}}` no Metabase com o valor padrão "Selecionar todos exceto: Ticket::Duplicado, Ticket::Cancelado" para manter a visão limpa, permitindo que o usuário altere se necessário.

## 2. Relacionamento com Etiquetas (Tags)
O DW utiliza uma estrutura de ponte para permitir que um chamado tenha múltiplas etiquetas sem duplicar linhas na tabela fato.

**Exemplo de Join para Relatórios de Tags:**
```sql
SELECT
  dt.name AS tag,
  COUNT(DISTINCT t.chamado) AS qtd
FROM metabase_tickets t
JOIN bridge_ticket_tags btt ON btt.ticket_id = t.chamado
JOIN dim_tags dt ON dt.tag_id = btt.tag_id
GROUP BY dt.name
```

## 3. Filtros Globais (Variáveis)
... (mantém os filtros anteriores) ...

## 4. Gráficos Adicionais Sugeridos
- **Ranking de Etiquetas:** Gráfico de barras mostrando quais tags são mais frequentes (ex: identificar volume de cancelados via tag).