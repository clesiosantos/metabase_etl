# Documentação: Dashboard Gestão a Vista - Aba Timeseries

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Timeseries**.

## 1. Regras de Negócio
- **Filtro de Exclusão Padrão:** Todas as consultas ignoram por padrão os tipos de solução `Ticket::Duplicado` e `Ticket::Cancelado`.
- **Foco Temporal:** As consultas são agrupadas por Mês (`ano_mes`) ou Dia (`data`) para mostrar tendências.

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
1. **Evolução Mensal (Abertos x Fechados):** Gráfico de barras ou linhas comparando o volume de entrada e saída por mês.
2. **Tendência de MTTR:** Gráfico de linha mostrando a variação do tempo médio de solução ao longo dos meses.
3. **Tendência de TTO:** Gráfico de linha mostrando a variação do tempo médio de resposta ao longo dos meses.
4. **Volume Diário (90 dias):** Gráfico de área ou linha para identificar picos de demanda diária.