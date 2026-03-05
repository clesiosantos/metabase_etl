# Documentação: Dashboard Gestão a Vista - Aba Chamado Geral

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Chamado Geral**.

## 1. Regras de Negócio
- **Filtro de Exclusão:** Por padrão, todos os indicadores ignoram chamados com tipo de solução `Ticket::Duplicado` e `Ticket::Cancelado`.
- **Chamados Abertos:** Considera qualquer chamado que **NÃO** esteja nos status 'Solucionado' ou 'Fechado'.
- **Chamados Fechados:** Considera apenas chamados com status 'Fechado'.

## 2. Filtros Globais (Variáveis)
Configure as variáveis no Metabase como **Filtro de Campo (Field Filter)**:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{periodo_abertura}}` | `data_id` | Data |
| `{{periodo_fechamento}}` | `data_fechamento` | Data |
| `{{cliente}}` | `entidade_cliente` | Categoria |
| `{{torre}}` | `grupo_solucao` | Categoria |
| `{{tecnico}}` | `nome_tecnico_responsavel` | Categoria |
| `{{agente_abertura}}` | `nome_solicitante` | Categoria |
| `{{agente_solucao}}` | `agente_solucionador` | Categoria |
| `{{status}}` | `status_chamado` | Categoria |
| `{{tipo_solucao}}` | `servico` | Categoria |
| `{{tipo_chamado}}` | `tipo_chamado` | Categoria |
| `{{prioridade}}` | `prioridade` | Categoria |
| `{{etiqueta}}` | `tags` | Categoria |

## 3. Descrição dos Gráficos

### 1. Total de Chamado Fechado (Número)
Exibe o volume acumulado de entregas (fechamentos) conforme os filtros aplicados.

### 2. Total de Chamados Aberto (Número)
Exibe o estoque atual de trabalho (backlog).

### 3. Chamados Aberto X Fechado - Visão Diária (Gráfico de Linhas)
**Análise de Fluxo:** Compara a quantidade de chamados que entraram (Criados) vs a quantidade que saiu (Fechados) nos últimos 30 dias.
- Se a linha de **Criados** estiver consistentemente acima da de **Fechados**, o backlog está aumentando.
- Se a linha de **Fechados** estiver acima, a equipe está reduzindo o backlog.

---
**Nota:** O gráfico diário utiliza a `dim_calendario` para garantir que dias sem movimento (ex: finais de semana) apareçam com valor zero em vez de sumirem do eixo X.