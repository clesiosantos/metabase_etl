# Documentação: Dashboard Gestão a Vista - Aba SLA

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **SLA**.

## 1. Regras de Negócio
- **Filtro de Exclusão:** Por padrão, todos os indicadores ignoram chamados com tipo de solução `Ticket::Duplicado` e `Ticket::Cancelado`.
- **Cálculo de %:** O percentual é calculado dividindo os chamados 'NO PRAZO' pelo total de chamados que possuem SLA definido (ignora 'SEM SLA').

## 2. Filtros Globais (Variáveis)
Configure as variáveis no Metabase como **Filtro de Campo (Field Filter)**:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{periodo_abertura}}` | `dim_calendario.data` | Data |
| `{{periodo_fechamento}}` | `metabase_tickets.data_fechamento` | Data |
| `{{cliente}}` | `metabase_tickets.entidade_cliente` | Categoria |
| `{{torre}}` | `metabase_tickets.grupo_solucao` | Categoria |
| `{{tecnico}}` | `metabase_tickets.nome_tecnico_responsavel` | Categoria |
| `{{agente_abertura}}` | `metabase_tickets.nome_solicitante` | Categoria |
| `{{agente_solucao}}` | `metabase_tickets.agente_solucionador` | Categoria |
| `{{status}}` | `metabase_tickets.status_chamado` | Categoria |
| `{{tipo_solucao}}` | `metabase_tickets.tipo_solucao` | Categoria |
| `{{tipo_chamado}}` | `metabase_tickets.tipo_chamado` | Categoria |
| `{{prioridade}}` | `metabase_tickets.prioridade` | Categoria |
| `{{etiqueta}}` | `dim_tags.name` | Categoria |

> **Nota sobre Etiquetas:** O filtro `{{etiqueta}}` deve ser mapeado obrigatoriamente para a coluna `name` da tabela `dim_tags`. A consulta utiliza uma subquery na tabela de ponte `bridge_ticket_tags` para garantir que o filtro funcione sem duplicar os registros de chamados.

## 3. Descrição dos Gráficos
... (mantém as descrições anteriores) ...