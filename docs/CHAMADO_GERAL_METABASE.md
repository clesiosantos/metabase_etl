# Documentação: Dashboard Gestão a Vista - Aba Chamado Geral

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Chamado Geral**.

## 1. Regras de Negócio
- **Disponibilidade de Dados:** Todas as tags estão disponíveis no DW.
- **Filtro Padrão:** Recomenda-se configurar o filtro `{{tipo_solucao}}` no Metabase com o valor padrão "Selecionar todos exceto: Ticket::Duplicado, Ticket::Cancelado" para manter a visão limpa.

## 2. Filtros Globais (Variáveis)
Configure as variáveis no Metabase como **Filtro de Campo (Field Filter)**:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{periodo_abertura}}` | `dim_calendario.data` | Data |
| `{{periodo_fechamento}}` | `metabase_tickets.data_fechamento` | Data |
| `{{cliente}}` | `metabase_tickets.entidade_cliente` | Categoria |
| `{{torre}}` | `metabase_tickets.grupo_solucao` | Categoria |
| `{{tecnico}}` | `metabase_tickets.nome_tecnico_responsavel` | Categoria |
| `{{solicitante}}` | `metabase_tickets.nome_solicitante` | Categoria |
| `{{status}}` | `metabase_tickets.status_chamado` | Categoria |
| `{{tipo_solucao}}` | `metabase_tickets.tipo_solucao` | Categoria |
| `{{tipo_chamado}}` | `metabase_tickets.tipo_chamado` | Categoria |
| `{{prioridade}}` | `metabase_tickets.prioridade` | Categoria |
| `{{etiqueta}}` | `dim_tags.name` | Categoria |

## 3. Descrição dos Gráficos
1. **Volume Total:** Card numérico com o total de chamados.
2. **Volume por Status:** Gráfico de pizza ou barras com a distribuição de status.
3. **Volume por Categoria:** Ranking das categorias mais utilizadas.
4. **Volume por Prioridade:** Distribuição por nível de prioridade.
5. **Ranking de Etiquetas:** Gráfico de barras mostrando a frequência das tags.