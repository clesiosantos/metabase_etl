# Documentação: Dashboard Gestão a Vista - Aba Backlog

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Backlog**.

## 1. Fonte de Dados
Todas as consultas utilizam a tabela `dw_glpi.metabase_tickets` com `JOIN` na `dw_glpi.dim_calendario`.

## 2. Filtros Globais (Variáveis)
Configure as variáveis no Metabase como **Filtro de Campo (Field Filter)**:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{periodo_abertura}}` | `dim_calendario.data` | Data |
| `{{cliente}}` | `metabase_tickets.entidade_cliente` | Categoria |
| `{{torre}}` | `metabase_tickets.grupo_solucao` | Categoria |
| `{{tecnico}}` | `metabase_tickets.nome_tecnico_responsavel` | Categoria |
| `{{solicitante}}` | `metabase_tickets.nome_solicitante` | Categoria |
| `{{status}}` | `metabase_tickets.status_chamado` | Categoria |
| `{{tipo_solucao}}` | `metabase_tickets.tipo_solucao` | Categoria |
| `{{tipo_chamado}}` | `metabase_tickets.tipo_chamado` | Categoria |
| `{{prioridade}}` | `metabase_tickets.prioridade` | Categoria |

## 3. Descrição dos Gráficos
... (mantém as descrições anteriores) ...