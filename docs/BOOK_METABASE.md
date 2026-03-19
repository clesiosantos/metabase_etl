# Documentação: Dashboard BOOK (Metabase)

Este dashboard é o ponto central de monitoramento, consolidando Incidentes, Requisições, Mudanças, Problemas e Timesheet.

## 📌 Filtros Globais (Configuração)
Para que os filtros funcionem em todos os cards simultaneamente, utilize os seguintes mapeamentos de variáveis no Metabase:

| Variável | Mapeamento por Tabela | Fonte de Dados do Filtro (SQL) |
| :--- | :--- | :--- |
| `{{periodo_abertura}}` | `dim_calendario.data` | Calendário Nativo |
| `{{cliente}}` | `entidade_cliente` | `SELECT DISTINCT entidade_cliente...` |
| `{{torre}}` | `grupo_solucao` | `SELECT DISTINCT grupo_solucao...` |
| **`{{agente}}`** | `agente_solucionador` (Tickets/Changes/Problems) e `tecnico` (Timesheet) | **`sql/filter_agentes.sql`** |
| `{{status}}` | `status_chamado` | `SELECT DISTINCT status_chamado...` |

### 💡 Dica: Filtro Unificado de Agentes
Para evitar que o filtro de agentes mostre apenas nomes de uma única tabela, utilize o script localizado em `sql/filter_agentes.sql` como a "Consulta de Filtragem" (Filter Query) no Metabase. Isso garante que colaboradores que atuam apenas em Mudanças ou apenas em Timesheet apareçam na lista.

## 🕒 Regras de Horário (Timezone)
- **Infraestrutura:** Servidores e Bancos operam em **UTC**.
- **Metabase:** Deve ser configurado para exibir os dados no timezone local do usuário, mas as consultas SQL brutas devem considerar que os dados no DW estão em UTC.

## 📈 Regras das Entidades

### 1. Tickets (Incidentes e Requisições)
- **SLA:** Calculado diretamente no Extractor para garantir performance.
- **Backlog:** Considera chamados com status diferente de 'Solucionado' e 'Fechado'.

### 2. Timesheet (Apontamento de Horas)
- **Unificação:** Consolida tarefas de todos os tipos de tickets + Formulário 142.
- **Qualidade:** Remove lançamentos "órfãos" (sem ticket pai) e lançamentos com 0 horas.
- **Duplicidade:** Se houver Form 142, as tarefas manuais do ticket são ignoradas.

### 3. Mudanças e Problemas
- **Mudanças:** Inclui campos de Ambiente, Classificação e Justificativa.
- **Problemas:** Inclui campo de Causa Raiz.

## ⚙️ Manutenção do DW
- **Logs de Erro:** Verifique a tabela `dw_glpi.etl_error` em caso de divergência de dados.
- **Logs de Execução:** Verifique `dw_glpi.etl_run` para acompanhar a volumetria de carga diária.