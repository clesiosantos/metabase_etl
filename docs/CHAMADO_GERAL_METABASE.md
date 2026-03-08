# Documentação: Dashboard Gestão a Vista - Aba Chamado Geral

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Chamado Geral**.

## 1. Regras de Negócio
- **Filtro de Exclusão Padrão:** Todas as consultas ignoram por padrão os tipos de solução `Ticket::Duplicado` e `Ticket::Cancelado`.
- **Definição de Fechado:** Chamados com status 'Solucionado' ou 'Fechado'.
- **Definição de Aberto:** Chamados com status diferente de 'Solucionado' e 'Fechado'.
- **Visão Diária:** O gráfico comparativo foca nos últimos 30 dias a partir da data atual.

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
1. **Total de Chamado Fechado:** Card numérico exibindo o volume de chamados solucionados/fechados. Possui drill-through para listagem detalhada.
2. **Total de Chamados Aberto:** Card numérico exibindo o volume de chamados que ainda não foram solucionados. Possui drill-through para listagem detalhada.
3. **Chamados Aberto X Fechado:** Gráfico de linhas ou barras empilhadas mostrando a evolução diária dos últimos 30 dias.