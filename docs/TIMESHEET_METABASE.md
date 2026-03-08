# Documentação: Dashboard Gestão a Vista - Aba TimeSheet

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **TimeSheet**.

## 1. Fonte de Dados
As consultas utilizam a tabela consolidada `dw_glpi.metabase_timesheet`, que agrupa lançamentos de:
- Tarefas de Chamados (`glpi_tickettasks`)
- Tarefas de Mudanças (`glpi_changetasks`)
- Tarefas de Problemas (`glpi_problemtasks`)
- Lançamentos diretos de Timesheet (se aplicável)

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
| `{{data_lancamento}}` | `metabase_timesheet.data_lancamento` | Data |

## 3. Descrição dos Gráficos
1. **Visão Geral de Horas:** Tabela detalhada com drill-down habilitado.
2. **Horas por Grupo Solucionador:** Gráfico de barras/pizza por torre.
3. **Horas por Cliente:** Ranking de consumo de horas por cliente.
4. **Horas por Técnico:** Produtividade individual em horas.
5. **Horas por Técnico / Tipo:** Comparativo entre horas comerciais e plantão.
6. **Horas por Total (Mensal):** Evolução temporal do esforço da equipe.
7. **Horas por Atividade:** Consolidado por tipo de ticket (Chamado, Mudança, Problema).