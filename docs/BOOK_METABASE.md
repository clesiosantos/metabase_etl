# Documentação: Dashboard BOOK (Metabase)

Este dashboard consolida a visão estratégica do GLPI com abas dedicadas a Incidentes, Requisições, Eventos, SLA, Mudanças, Problemas e Timesheet.

## 📌 Filtros Globais (Padrão)
Para garantir que os cards funcionem em conjunto, utilize os mapeamentos:
- `{{periodo_abertura}}` → `dim_calendario.data`
- `{{cliente}}` → `entidade_cliente`
- `{{torre}}` → `grupo_solucao` (ou `grupo_solucionador`)
- `{{status}}` → `status_chamado`

## 🕒 Configuração de Infraestrutura
O ETL e o DW operam em **UTC**.
- **Servidor:** Deve estar sincronizado via NTP.
- **Timezone:** Recomendado configurar o OS como UTC (`timedatectl set-timezone UTC`).

## 📈 Regras das Abas (Destaques)

### Timesheet & Horas
- **Fonte:** `metabase_timesheet`.
- **Composição:** Unifica tarefas manuais e o formulário de apontamento (Form 142).
- **Regra de Sucesso:** Filtra apenas formulários que possuem ticket pai vinculado.

### Mudanças (Changes)
- **Abertas:** Status NOT IN ('Aplicado', 'Cancelado', 'Recusado', 'Fechado').
- **Sucesso:** `% de Mudanças` calculada sobre o total fechado onde a solução contém "sucesso".

### Problemas (Problems)
- Inclui análise de **Causa Raiz** via campos customizados do plugin Fields.

## ⚙️ Automação (Systemd)
O agendamento é feito via Systemd Timer no Oracle Linux 9.6:
- `systemctl list-timers`: Verifica o próximo agendamento.
- `journalctl -u etl-glpi-metabase.service`: Acompanha a saída em tempo real.