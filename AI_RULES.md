# Regras de Desenvolvimento de IA - ETL GLPI → DW

## 1. Stack Técnica & Padrões
- **PHP 8.x CLI** (Strict Types).
- **PDO Nativo:** Sem ORMs. Uso obrigatório de Prepared Statements.
- **Timezone:** Estritamente **UTC**. Conexões devem executar `SET SESSION time_zone = '+00:00'`.
- **Idempotência:** Loaders devem usar `INSERT ... ON DUPLICATE KEY UPDATE`.

## 2. Arquitetura Modular
- **Extractors:** Devem lidar com JOINs complexos e filtragem de "is_deleted".
- **Transformers:** Lógica stateless para normalização de dados e criação de faixas de tempo.
- **Loaders:** Focados em performance e mapeamento de colunas.
- **Jobs:** Devem gerenciar transações e registrar logs via `EtlRun`/`EtlError`.

## 3. Regras Específicas de Negócio
- **Timesheet Unificado:** Deve consolidar `glpi_tickettasks`, `glpi_changetasks`, `glpi_problemtasks` e `Formcreator (Form 142)`.
- **Filtro de Órfãos:** Registros de timesheet/forms sem ticket pai vinculado **devem ser removidos** da carga através de INNER JOIN no extrator.
- **Filtro de Tempo:** Registros com tempo de execução zerado (0 segundos/horas) **devem ser ignorados** na extração.
- **Prevenção de Duplicidade:** Tarefas de tickets (`glpi_tickettasks`) cujos chamados possuem vínculo com `PluginFormcreatorFormAnswer` **devem ser ignoradas** para evitar contagem dupla com os dados do formulário.
- **SLA:** Cálculos de status (No Prazo, Em Risco, Fora do Prazo) devem ser feitos no SQL do Extractor para garantir consistência.

## 4. Observabilidade
- Todo erro deve ser capturado no Job e persistido na tabela `etl_error`.
- O Checkpoint só deve ser atualizado após o `commit` bem-sucedido de todos os batches da entidade.