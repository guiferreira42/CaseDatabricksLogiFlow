-- ============================================================
-- SETUP: Criação do Catálogo e Schemas (Medallion Architecture)
-- ============================================================

-- Criação do catálogo
CREATE CATALOG IF NOT EXISTS logiflow;

USE CATALOG logiflow;

-- Criação das camadas
CREATE SCHEMA IF NOT EXISTS bronze
  COMMENT 'Camada Raw - Dados extraídos diretamente do ERP SAP e simulador logiflow';

-- Volume Unity Catalog para recepção dos arquivos CSV simulados pelo Python
CREATE VOLUME IF NOT EXISTS logiflow.bronze.raw_data
  COMMENT 'Volume Raw Data do LogiFlow';

CREATE SCHEMA IF NOT EXISTS silver
  COMMENT 'Camada Curated - Dados limpos, deduplicados, com hashes de idempotência e histórico (SCD)';

CREATE SCHEMA IF NOT EXISTS gold
  COMMENT 'Camada Analytics - Fatos, Dimensões e Views prontas para consumo (PowerBI/Dashboards)';


