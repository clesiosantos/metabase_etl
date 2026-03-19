# Documentação: Dashboard Gestão a Vista - Aba TimeSheet

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **TimeSheet**.

## 1. Fonte de Dados
...

## 2. Filtros Globais (Variáveis)
Configure as variáveis no Metabase como **Filtro de Campo (Field Filter)**:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{cliente}}` | `metabase_timesheet.cliente` | Categoria |
| `{{torre}}` | `metabase_timesheet.grupo_solucionador` | Categoria |
| `{{agente}}` | `metabase_timesheet.tecnico` | Categoria |
| `{{tipo_ticket}}` | `metabase_timesheet.tipo_ticket` | Categoria |
| `{{periodo_abertura}}` | `metabase_timesheet.data_abertura_pai` | Data |
| `{{periodo_fechamento}}` | `metabase_timesheet.data_fechamento_pai` | Data |
| `{{data_lancamento}}` | `metabase_timesheet.data_lancamento` | Data |

## 3. Descrição dos Gráficos
...