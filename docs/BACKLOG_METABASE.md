# Documentação: Dashboard Gestão a Vista - Aba Backlog

Este documento descreve a configuração das perguntas (cards) no Metabase para a aba de **Backlog**.

## 1. Fonte de Dados
Todas as consultas utilizam a view `dw_glpi.v_tickets_abertos`, que filtra automaticamente chamados que **NÃO** estão nos status 'Solucionado' ou 'Fechado'.

## 2. Filtros Globais (Variáveis)
Para que os filtros funcionem, configure as variáveis no Metabase como **Filtro de Campo (Field Filter)** apontando para as colunas da tabela `metabase_tickets`:

| Variável | Coluna de Mapeamento | Tipo de Filtro |
| :--- | :--- | :--- |
| `{{periodo}}` | `data_id` | Data |
| `{{cliente}}` | `entidade_cliente` | Categoria |
| `{{grupo}}` | `grupo_solucao` | Categoria |
| `{{agente}}` | `nome_tecnico_responsavel` | Categoria |
| `{{prioridade}}` | `prioridade` | Categoria |
| `{{status}}` | `status_chamado` | Categoria |
| `{{canal}}` | `canal` | Categoria |

## 3. Descrição dos Gráficos

### 1. Volume Total (Número)
Exibe o tamanho atual da fila de trabalho. Útil para KPIs de "Backlog Total".

### 2. Volume por Cliente (Gráfico de Barras Horizontal)
Identifica quais clientes possuem maior demanda pendente.

### 3. Volume por Status (Gráfico de Pizza/Donut)
Mostra a distribuição operacional (ex: quantos estão 'Pendentes' aguardando o usuário vs 'Novo').

### 4. Volume por Torre (Gráfico de Barras)
Visão por equipe técnica (NOC, Service Desk, Infra, etc.).

### 5. Volume por Aging (Gráfico de Barras)
**Crítico para Gestão:** Mostra a idade dos chamados. Chamados na faixa "Maior que 30 dias" devem ser priorizados para evitar insatisfação.

### 6. Volume Dias Sem Atualizar (Gráfico de Barras)
**Foco em Engajamento:** Identifica chamados "esquecidos" pelos técnicos. Chamados com "Maior que 7 dias" sem atualização indicam falha no acompanhamento.

---
**Nota:** As ordenações das faixas (Aging e Atualização) são garantidas pela função `FIELD()` no SQL para que o gráfico faça sentido visual (do menor para o maior tempo).