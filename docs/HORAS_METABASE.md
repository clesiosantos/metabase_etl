# Documentação: Dashboard Horas - Aba Horas

Este documento descreve a configuração das perguntas (cards) no Metabase para o dashboard de **Horas**.

## 1. Fonte de Dados
As consultas utilizam a tabela `dw_glpi.metabase_timesheet`.

## 2. Filtros Globais (Variáveis)
Configure as variáveis no Metabase como **Filtro de Campo (Field Filter)**:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{cliente}}` | `metabase_timesheet.cliente` | Categoria |
| `{{torre}}` | `metabase_timesheet.grupo_solucionador` | Categoria |
| `{{tecnico}}` | `metabase_timesheet.tecnico` | Categoria |
| `{{tipo_ticket}}` | `metabase_timesheet.tipo_ticket` | Categoria |
| `{{periodo_abertura}}` | `metabase_timesheet.data_abertura_pai` | Data |
| `{{periodo_fechamento}}` | `metabase_timesheet.data_fechamento_pai` | Data |

## 3. Descrição dos Gráficos

1.  **Visão Geral de Horas**: Tabela detalhada com drill-down para os registros originais.
2.  **Horas por Grupo Solucionador**: Gráfico de barras mostrando o esforço por torre/grupo.
3.  **Horas por Cliente**: Ranking de consumo de horas por cliente.
4.  **Horas por Técnico / Colaborador**: Gráfico de barras com o total de horas por técnico.
5.  **Horas por Técnico / Tipo de Horas**: Gráfico comparativo (empilhado) entre horas Comerciais, Plantão e outros.
6.  **Horas por Total (Mensal)**: Evolução temporal do total de horas lançadas por mês.
7.  **Horas por Total (Atividade)**: Gráfico consolidado por tipo de atividade (Chamado, Mudança, Problema).