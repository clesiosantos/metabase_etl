# AI Development Rules - ETL GLPI → DW

This document defines the technical stack, architectural patterns, and library usage rules for this project.

## 1. Tech Stack
- **Language:** PHP 8.x (CLI mode).
- **Database:** MySQL 8.0+ (Source: GLPI, Target: Data Warehouse).
- **Database Access:** Native PHP `PDO` (no ORM allowed to maintain performance and control over complex JOINs).
- **Environment Management:** Custom `Config` class loading `.env` files.
- **Concurrency Control:** MySQL-based locking via `GET_LOCK()` (implemented in `src/Lock.php`).
- **Observability:** Custom logging to files (`src/Logger.php`) and database tracking (`etl_run`, `etl_error`, `etl_checkpoint`).
- **Architecture:** Modular ETL pattern (Extractors, Transformers, Loaders, Jobs).

## 2. Library & Component Rules

### 2.1 Database (MySQL/PDO)
- **Always** use `PDO` with prepared statements.
- **Never** use `mysqli` or raw string concatenation for queries.
- **Timezones:** The system operates strictly in **UTC**. Database connections must set `SET SESSION time_zone = '+00:00'`.

### 2.2 ETL Architecture
- **Extractors (`src/Extractors/`):** Responsible for fetching IDs and detailed data from the source (GLPI). Must handle complex JOINs.
- **Transformers (`src/Transformers/`):** Responsible for data cleaning and normalization. Logic should be stateless.
- **Loaders (`src/Loaders/`):** Responsible for `UPSERT` operations (`INSERT ... ON DUPLICATE KEY UPDATE`) in the target DW.
- **Jobs (`src/Jobs/`):** Orchestrate the flow between Extractor, Transformer, and Loader for a specific entity.

### 2.3 Error Handling & Observability
- **Logging:** Use the `Logger` class for file-based logs.
- **Tracking:** Every execution must be registered in `etl_run` using the `EtlRun` class.
- **Errors:** Catch exceptions at the Job level and log them to the `etl_error` table using `EtlError`.
- **Checkpoints:** Use `Checkpoint::get()` and `Checkpoint::set()` to manage incremental loads.

### 2.4 Coding Standards
- **Strict Typing:** Use `declare(strict_types=1);` in all new files.
- **Naming:** Use PascalCase for Classes and camelCase for methods/variables.
- **Idempotency:** All Loaders must be idempotent (running the same data twice should not create duplicates).

## 3. Prohibited Actions
- **No External Dependencies:** Do not add Composer packages unless strictly necessary and approved.
- **No UI Logic:** This is a CLI tool; do not add HTML/CSS/JS.
- **No Hardcoded Credentials:** Always use `Config::get()` or `$_ENV`.