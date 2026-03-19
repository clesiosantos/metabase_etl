# ETL GLPI → Data Warehouse (MySQL) → Metabase

Este projeto realiza a extração, transformação e carga (ETL) de dados do GLPI para um Data Warehouse (DW) em MySQL, otimizado para consumo via Metabase.

## 🚀 Arquitetura
O sistema segue o padrão modular:
- **Extractors:** Consultas complexas no banco de origem (GLPI).
- **Transformers:** Limpeza, normalização e criação de faixas (Aging, Sem Atualização).
- **Loaders:** Operações de `UPSERT` (idempotência) no banco de destino.
- **Jobs:** Orquestração do fluxo de uma entidade específica.
- **Checkpoint:** Controle de carga incremental baseado em data de modificação.

## 📂 Entidades Processadas
- **Tickets:** Incidentes e Requisições com cálculo de SLA (TTO/TTR).
- **Changes:** Gestão de Mudanças com campos customizados de ambiente e classificação.
- **Problems:** Gestão de Problemas com análise de causa raiz.
- **Timesheet:** Unificação de lançamentos de tarefas (`Ticket`, `Change`, `Problem`) e formulários de apontamento de horas (`Form 142`).
- **Tags:** Sincronização de dimensões e pontes (N:N) para todas as entidades.

## 🛠️ Comandos de Execução
Todos os comandos devem ser executados via CLI a partir da raiz do projeto:

```bash
# Processar tudo (Incremental)
php bin/etl.php all

# Processar tudo (Carga Total)
php bin/etl.php all --full

# Processar entidade específica
php bin/etl.php tickets
php bin/etl.php changes
php bin/etl.php problems
php bin/etl.php timesheet
```

## 📊 Observabilidade
O sistema registra toda execução no DW:
- `etl_run`: Status, volumetria (IDs selecionados vs Upserted) e validações.
- `etl_error`: Logs detalhados de falhas com contexto JSON.
- `etl_checkpoint`: Último timestamp de sucesso por entidade.
- `logs/etl.log`: Log detalhado em arquivo para auditoria do sistema.

## 📋 Pré-requisitos
- PHP 8.x (CLI) com extensões `pdo_mysql`.
- MySQL 8.0+ em ambos os bancos.
- Timezone configurado como **UTC** no servidor e bancos de dados.