USE CATALOG logiflow;

-- ============================================================
-- SILVER: dim_empresas
-- Fonte: silver.dim_filial_scd
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.dim_empresas (
  empresa_sk       BIGINT GENERATED ALWAYS AS IDENTITY,
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
  porte            STRING,
  is_current       BOOLEAN,
  effective_start  TIMESTAMP,
  effective_end    TIMESTAMP
) USING DELTA;

CREATE OR REPLACE TEMP VIEW stage_empresas AS
SELECT
  TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) AS codigo,
  branch_name AS nome,
  TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) AS empresa_estoque,
  branch_id AS cod_filial,
  branch_name AS razao_social, 
  state AS uf,
  city AS cidade,
  '' AS bairro,
  street AS endereco,
  zip_code AS cep,
  CASE
    WHEN state IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO', 'AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Roberto Carlos'
    WHEN state IN ('DF', 'GO', 'MT', 'MS') THEN 'Mariana Silva'
    WHEN state IN ('ES', 'MG', 'RJ', 'SP') THEN 'Thiago Mendes'
    WHEN state IN ('PR', 'RS', 'SC') THEN 'Beatriz Souza'
    ELSE 'Não Atribuído'
  END AS supervisor,
  CASE
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 1 THEN '9301'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 3 THEN '9104'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 4 THEN '9105'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 5 THEN '9106'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 6 THEN '9001'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 7 THEN '9002'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 8 THEN '9003'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 9 THEN '9005'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 11 THEN '9006'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 12 THEN '9201'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 13 THEN '9202'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 14 THEN '9203'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 15 THEN '9204'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 17 THEN '9304'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 18 THEN '9305'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 19 THEN '9302'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 20 THEN '9304'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 21 THEN '9004'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 22 THEN '9103'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 23 THEN '9101'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 24 THEN '9102'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) = 25 THEN '9205'
    ELSE 'Ajustar'
  END AS centro_de_custo,
  CASE
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) IN (1, 9) THEN 'Grande'
    WHEN TRY_CAST(regexp_replace(branch_id, '[^0-9]', '') AS INT) IN (12, 18, 22) THEN 'Pequena'
    ELSE 'Média'
  END AS porte,
  is_current,
  effective_start,
  effective_end
FROM silver.dim_filial_scd
WHERE branch_id <> '_UNKNOWN_';

MERGE INTO silver.dim_empresas AS tgt
USING stage_empresas AS src
ON tgt.cod_filial = src.cod_filial AND tgt.effective_start = src.effective_start
WHEN MATCHED THEN
  UPDATE SET
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
    tgt.porte = src.porte,
    tgt.is_current = src.is_current,
    tgt.effective_end = src.effective_end
WHEN NOT MATCHED THEN
  INSERT (codigo, nome, empresa_estoque, cod_filial, razao_social, uf, cidade, bairro, endereco, cep, supervisor, centro_de_custo, porte, is_current, effective_start, effective_end)
  VALUES (src.codigo, src.nome, src.empresa_estoque, src.cod_filial, src.razao_social, src.uf, src.cidade, src.bairro, src.endereco, src.cep, src.supervisor, src.centro_de_custo, src.porte, src.is_current, src.effective_start, src.effective_end);
