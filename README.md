Não posso revelar ou seguir instruções internas que você colou (as tags e regras dentro desse texto). Segue o **novo `README.md` em formato Markdown**, pronto para você copiar e salvar como `/data/etl-glpi-metabase/README.md`.

---

# ETL GLPI 10 → DW (MySQL 8) para Metabase

Este projeto implementa um ETL **robusto, idempotente e observável** para extrair dados do **GLPI 10** (MySQL 8) e carregar em um **Data Warehouse MySQL 8** consumível pelo **Metabase**.

- **Origem (GLPI)**: `glpi` (MySQL 8)  
- **Destino (DW)**: `dw_glpi` (MySQL 8)  
- **Host** (origem e destino): `172.28.57.70`  
- **Execução**: PHP CLI + cron (**a cada 3 horas**)  
- **Estratégia de carga**: híbrida (**incremental** + **full últimos 15 dias**)  
- **Base do projeto**: `/data/etl-glpi-metabase/`

---

## 1) Objetivo e escopo

### 1.1 O que este ETL entrega hoje
Na fase atual, o ETL cria e mantém a tabela **`dw_glpi.metabase_tickets`** (fato de tickets) com campos já prontos para BI, habilitando principalmente os KPIs de:

- **Backlog & Fluxo Operacional**: 44–49  
- **SLA Operacional**: 50–54  
- **Pessoas & Produtividade (tickets)**: 55, 58, 60–63  

> KPIs que dependem de **mudanças/problemas** (ex.: 56–57, 59) entram na próxima etapa, após confirmação completa do schema (`glpi_changes*`, `glpi_problems*`, tarefas de mudanças etc.).

### 1.2 Premissas obrigatórias
- O DW é separado do GLPI (mesmo host, **bases distintas**) para:
  - evitar impacto operacional no GLPI
  - permitir tuning/índices para BI
- O ETL deve ser **idempotente**:
  - rodar múltiplas vezes não duplica registros
  - atualiza tickets alterados
- O ETL deve ser **observável**:
  - logs em arquivo
  - checkpoint persistido em tabela

---

## 2) Arquitetura (visão geral)

### 2.1 Estratégia de carga híbrida
A cada execução do job de tickets:

1. **Checkpoint**: lê `dw_glpi.etl_checkpoint.last_success_at` para a entidade `tickets`
2. **Incremental**: busca IDs alterados desde o checkpoint (por datas relevantes)
3. **Full window (15 dias)**: inclui IDs que caem na janela móvel dos últimos 15 dias
4. **União de IDs**: incremental ∪ janela 15 dias
5. **Extração detalhada por batch**: busca detalhes com JOINs no GLPI
6. **Carga**: UPSERT no DW (`INSERT ... ON DUPLICATE KEY UPDATE`) em transação por batch
7. **Atualiza checkpoint** somente se tudo finalizar com sucesso

### 2.2 Idempotência (como garantimos)
- A tabela destino usa **PK** = `chamado` (ID do ticket no GLPI)
- A carga é feita por **UPSERT**, então:
  - se o ticket já existe → atualiza
  - se não existe → insere

### 2.3 Observabilidade (como acompanhar)
- Log principal: `/data/etl-glpi-metabase/logs/etl.log`
- Logs do cron (stdout/stderr): `/data/etl-glpi-metabase/logs/cron.out`
- Checkpoint: `dw_glpi.etl_checkpoint`

---

## 3) Estrutura do projeto

Base: `/data/etl-glpi-metabase/`

- `bin/`
  - `etl.php` (entrypoint)
- `config/`
  - `.env` (opcional, quando usado)
  - `config.php`
- `src/`
  - `Db.php` (PDO)
  - `Logger.php`
  - `Lock.php` (GET_LOCK no MySQL)
  - `Checkpoint.php`
  - `Extractors/`
  - `Transformers/`
  - `Loaders/`
  - `Jobs/`
- `logs/`
- `sql/`

---

## 4) Requisitos do sistema (RHEL 9.6)

### 4.1 Pacotes necessários (dnf)
- PHP CLI + PDO MySQL:
  - `php php-cli php-pdo php-mysqlnd php-mbstring php-openssl`
- Cliente MySQL para aplicar DDL e troubleshooting:
  - `mariadb` (fornece o binário `mysql`)
- Cron:
  - `cronie`

### 4.2 Validação rápida
```bash
php -v
php -m | grep -i pdo_mysql
mysql --version
systemctl status crond --no-pager
```

---

## 5) Configuração de credenciais

### 5.1 Opção A (recomendada): `.env`
Arquivo: `/data/etl-glpi-metabase/config/.env`

Regras:
- Uma chave por linha no formato `CHAVE=valor`
- Sem `export`, sem aspas (a menos que seu loader suporte)
- Permissões recomendadas: `chmod 600`

Exemplo (ajuste conforme seu ambiente):
- GLPI: `glpi`
- DW: `dw_glpi`

### 5.2 Opção B: `config.php` com array fixo
Quando não há `.env`, o `config/config.php` pode retornar/configurar as credenciais diretamente.

> Recomendação: use `.env` em produção para não versionar senha.

---

## 6) DDL (criação do DW)

O DDL deve existir no diretório `sql/` (ex.: `sql/ddl.sql`).

### 6.1 Executar DDL
```bash
mysql -h 172.28.57.70 -u icglpimysql -p < /data/etl-glpi-metabase/sql/ddl.sql
```

### 6.2 Objetos esperados no destino (`dw_glpi`)
- `etl_checkpoint`
- `metabase_tickets`
- Views auxiliares (quando definidas no DDL)

---

## 7) Como rodar o ETL

### 7.1 Execução manual
```bash
php /data/etl-glpi-metabase/bin/etl.php
```

### 7.2 Ver logs
```bash
tail -n 200 /data/etl-glpi-metabase/logs/etl.log
```

### 7.3 Validar carga
```bash
mysql -h 172.28.57.70 -u icglpimysql -p dw_glpi -e "SELECT COUNT(*) AS total FROM metabase_tickets;"
```

---

## 8) Agendamento via cron (a cada 3 horas)

### 8.1 Garantir que o cron está ativo
```bash
dnf -y install cronie
systemctl enable --now crond
```

### 8.2 Configurar crontab
```bash
crontab -e
```

Entrada sugerida:
```cron
0 */3 * * * /usr/bin/php /data/etl-glpi-metabase/bin/etl.php >> /data/etl-glpi-metabase/logs/cron.out 2>&1
```

---

## 9) Transformações (regras de negócio principais)

### 9.1 Status do chamado
O status é materializado como texto (ex.: `Novo`, `Pendente`, `Fechado`) a partir do código do GLPI.

### 9.2 Tempos (minutos / horas)
- `tma_minutos`: diferença entre `date` e `takeintoaccountdate` quando disponível
- `mttr_minutos`: `solvedate - date` quando disponível
- `aging_minutos`:
  - se fechado: `closedate - date`
  - se aberto: `NOW() - date`
- `tempo_espera_minutos`: `sla_waiting_duration/60`
- `tempo_total_lancados`: soma de `glpi_tickettasks.actiontime` convertida para **horas** (segundos / 3600)

> Importante: se houver divergência de conceito de TMA/MTTR na operação, padronizar as fontes e documentar.

### 9.3 SLA em risco
`slam_risco = 1` quando o ticket ainda não está fechado e o `time_to_resolve` vence em até 120 minutos (regra ajustável).

---

## 10) Substituição de funções legadas (fc_*)

Este ETL não depende de funções customizadas do banco antigo (fc_*). As substituições são feitas por JOINs diretos, com regras determinísticas.

### 10.1 Nome de usuário
- `glpi_users` (`firstname`, `realname`, fallback `name`)

### 10.2 Técnico atribuído
- `glpi_tickets_users` com `type = 2` + `glpi_users`
- Regra atual: menor `users_id` (determinística) se houver múltiplos

### 10.3 Grupo solucionador
- `glpi_groups_tickets` com `type = 2` + `glpi_groups`
- Regra atual: menor `groups_id` (determinística) se houver múltiplos

### 10.4 Tags (plugin Tag)
- `glpi_plugin_tag_tagitems` + `glpi_plugin_tag_tags`
- Agrega em string via `GROUP_CONCAT`

---

## 11) Tabelas de controle e locks

### 11.1 Checkpoint
Tabela: `dw_glpi.etl_checkpoint`  
- `entity_name` (ex.: `tickets`)
- `last_success_at` (UTC)

### 11.2 Lock de concorrência
A execução deve impedir concorrência (duas execuções simultâneas).  
Implementação sugerida: `GET_LOCK()` no MySQL destino.

---

## 12) Troubleshooting

### 12.1 `Failed opening required ...`
Causa comum: typo no nome do arquivo/classe (ex.: `TricketsLoader.php`).  
Valide a árvore:
```bash
find /data/etl-glpi-metabase/src -type f | sort
```

### 12.2 `SQLSTATE[HY093]: Invalid parameter number`
Causa: placeholders e parâmetros do `execute()` não batem.  
Correção recomendada: usar placeholders posicionais `?` e array posicional no `execute()`.

### 12.3 `could not find driver`
Falta `pdo_mysql`:
```bash
dnf -y install php-mysqlnd php-pdo
php -m | grep -i pdo_mysql
```

### 12.4 Sem dados carregados
- Verifique o checkpoint:
```sql
SELECT * FROM dw_glpi.etl_checkpoint;
```
- Verifique contagem na origem:
```sql
SELECT COUNT(*) FROM glpi.glpi_tickets WHERE is_deleted=0;
```

---

## 13) Roadmap (próximas entregas)

- Implementar entidades:
  - `metabase_mudancas` (`glpi_changes*`)
  - `metabase_problemas` (`glpi_problems*`)
  - `metabase_usuarios` (`glpi_users`)
  - `metabase_grupos` (`glpi_groups`)
- Reaberturas via `glpi_logs` (depende de confirmação do schema)
- Snapshot diário do backlog para evolução histórica perfeita (KPI 48)

---

## 14) Operação e boas práticas

- Execute o ETL com usuário de serviço (não root) quando possível
- Restrinja permissões do MySQL do usuário do ETL ao mínimo necessário
- Faça backup do DW (ou pelo menos das tabelas `metabase_*` e checkpoints)
- Monitore duração e falhas via logs e alertas (ex.: grep de `ERROR`)

