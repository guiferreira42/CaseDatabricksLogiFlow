USE CATALOG logiflow;

-- ============================================================
-- GOLD: dim_empresas
-- Fonte: silver.dim_empresas
-- Objetivo: Tabela dimensão final de empresas, consumida pelo PBI
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_empresas (
  empresa_sk       BIGINT,
  codigo           INT,
  nome             STRING,
  empresa_estoque  INT,
  cod_filial       STRING,
  razao_social     STRING,
  uf               STRING,
  cidade           STRING,
  bairro           STRING,
  endereco         STRING,
  cep              STRING,
  supervisor       STRING,
  centro_de_custo  STRING,
  porte            STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW stage_gold_empresas AS
SELECT
  empresa_sk,
  codigo,
  nome,
  empresa_estoque,
  cod_filial,
  razao_social,
  uf,
  cidade,
  bairro,
  endereco,
  cep,
  supervisor,
  centro_de_custo,
  porte
FROM silver.dim_empresas
WHERE is_current = TRUE;

MERGE INTO gold.dim_empresas AS tgt
USING stage_gold_empresas AS src
ON tgt.cod_filial = src.cod_filial
WHEN MATCHED THEN
  UPDATE SET
    tgt.empresa_sk = src.empresa_sk,
    tgt.codigo = src.codigo,
    tgt.nome = src.nome,
    tgt.empresa_estoque = src.empresa_estoque,
    tgt.razao_social = src.razao_social,
    tgt.uf = src.uf,
    tgt.cidade = src.cidade,
    tgt.bairro = src.bairro,
    tgt.endereco = src.endereco,
    tgt.cep = src.cep,
    tgt.supervisor = src.supervisor,
    tgt.centro_de_custo = src.centro_de_custo,
    tgt.porte = src.porte
WHEN NOT MATCHED THEN
  INSERT (empresa_sk, codigo, nome, empresa_estoque, cod_filial, razao_social, uf, cidade, bairro, endereco, cep, supervisor, centro_de_custo, porte)
  VALUES (src.empresa_sk, src.codigo, src.nome, src.empresa_estoque, src.cod_filial, src.razao_social, src.uf, src.cidade, src.bairro, src.endereco, src.cep, src.supervisor, src.centro_de_custo, src.porte);

-- Registro desconhecido
INSERT INTO gold.dim_empresas
SELECT 0, 0, 'Desconhecida', 0, '_UNKNOWN_', 'Desconhecida', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Desconhecido'
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_empresas WHERE cod_filial = '_UNKNOWN_');
