# ETL GLPI → Data Warehouse (MySQL)

Sistema de integração de dados para Dashboards estratégicos no Metabase.

## 📂 Estrutura de Documentação
- `docs/BOOK_METABASE.md`: Guia mestre de configuração do Dashboard.
- `docs/TIMESHEET_METABASE.md`: Detalhes específicos da unificação de horas.
- `docs/SLA_METABASE.md`: Regras de cálculo de TTO e TTR.
- `AI_RULES.md`: Regras de desenvolvimento para manutenção do código.

## 🛠️ Ferramentas de Suporte
- `sql/filter_agentes.sql`: SQL pronto para criar o filtro de agentes no Metabase (resolve conflitos de collation).
- `bin/debug_change.php`: Script CLI para validar dados de uma mudança específica.
- `bin/debug_change_task.php`: Script CLI para validar sincronização de datas de lançamento.

## 🚀 Como Executar
```bash
# Sincronização Incremental (Diária/Horária)
php bin/etl.php all

# Recarga Total (Correção de Histórico)
php bin/etl.php all --full
```

---
*Desenvolvido por 3P Systems — www.3psystems.com.br*