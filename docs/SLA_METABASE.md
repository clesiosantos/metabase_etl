# Documentação: Dashboard Gestão a Vista - Aba SLA

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **SLA**.

## 1. Regras de Negócio
- **Filtro de Exclusão:** Por padrão, todos os indicadores ignoram chamados com tipo de solução `Ticket::Duplicado` e `Ticket::Cancelado`.
- **Cálculo de %:** O percentual é calculado dividindo os chamados 'NO PRAZO' ou 'EM RISCO' pelo total de chamados que possuem SLA definido (ignora 'SEM SLA').
- **TTO (Time to Own):** SLA de Resposta.
- **TTR (Time to Resolve):** SLA de Solução.

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

### 1. % de SLA de Resposta - Últimos 6 meses
Gráfico de linha ou barras mostrando a evolução mensal do TTO. Meta sugerida: 95%.

### 2. % de SLA de Solução - Últimos 6 meses
Gráfico de linha ou barras mostrando a evolução mensal do TTR. Meta sugerida: 90%.

### 3. % SLA Resposta Diário
Gráfico de linha para acompanhamento tático do dia a dia. Permite identificar quedas de performance em dias específicos.

### 4. % SLA de Solução Diário
Gráfico de linha para acompanhamento tático da resolução diária.

---
**Nota:** O uso de `NULLIF` nas consultas evita erros de "divisão por zero" caso não existam chamados com SLA no período filtrado.