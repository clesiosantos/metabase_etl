# Regras de Desenvolvimento de IA - ETL GLPI → DW

Este documento define a stack técnica, padrões arquiteturais e regras de uso de bibliotecas para este projeto.

## 1. Stack Técnica
- **Linguagem:** PHP 8.x (modo CLI).
- **Banco de Dados:** MySQL 8.0+ (Origem: GLPI, Destino: Data Warehouse).
- **Acesso ao Banco de Dados:** PHP `PDO` nativo (não é permitido ORM para manter performance e controle sobre JOINs complexos).
- **Gerenciamento de Ambiente:** Classe `Config` customizada carregando arquivos `.env`.
- **Controle de Concorrência:** Bloqueio baseado em MySQL via `GET_LOCK()` (implementado em `src/Lock.php`).
- **Observabilidade:** Logs customizados em arquivos (`src/Logger.php`) e rastreamento em banco de dados (`etl_run`, `etl_error`, `etl_checkpoint`).
- **Arquitetura:** Padrão ETL modular (Extractors, Transformers, Loaders, Jobs).

## 2. Regras de Bibliotecas e Componentes

### 2.1 Banco de Dados (MySQL/PDO)
- **Sempre** use `PDO` com prepared statements.
- **Nunca** use `mysqli` ou concatenação direta de strings para queries.
- **Timezones:** O sistema opera estritamente em **UTC**. As conexões com o banco de dados devem definir `SET SESSION time_zone = '+00:00'`.

### 2.2 Arquitetura ETL
- **Extractors (`src/Extractors/`):** Responsáveis por buscar IDs e dados detalhados da origem (GLPI). Devem lidar com JOINs complexos.
- **Transformers (`src/Transformers/`):** Responsáveis pela limpeza e normalização dos dados. A lógica deve ser stateless (sem estado).
- **Loaders (`src/Loaders/`):** Responsáveis por operações de `UPSERT` (`INSERT ... ON DUPLICATE KEY UPDATE`) no DW de destino.
- **Jobs (`src/Jobs/`):** Orquestram o fluxo entre Extractor, Transformer e Loader para uma entidade específica.

### 2.3 Tratamento de Erros e Observabilidade
- **Logging:** Use a classe `Logger` para logs em arquivo.
- **Rastreamento:** Toda execução deve ser registrada em `etl_run` usando a classe `EtlRun`.
- **Erros:** Capture exceções no nível do Job e registre-as na tabela `etl_error` usando `EtlError`.
- **Checkpoints:** Use `Checkpoint::get()` e `Checkpoint::set()` para gerenciar cargas incrementais.

### 2.4 Padrões de Código
- **Tipagem Estrita:** Use `declare(strict_types=1);` em todos os novos arquivos.
- **Nomenclatura:** Use PascalCase para Classes e camelCase para métodos/variáveis.
- **Idempotência:** Todos os Loaders devem ser idempotentes (executar os mesmos dados duas vezes não deve criar duplicatas).

## 3. Ações Proibidas
- **Sem Dependências Externas:** Não adicione pacotes Composer a menos que seja estritamente necessário e aprovado.
- **Sem Lógica de UI:** Esta é uma ferramenta CLI; não adicione HTML/CSS/JS.
- **Sem Credenciais Hardcoded:** Sempre use `Config::get()` ou `$_ENV`.
