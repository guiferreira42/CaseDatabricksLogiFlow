USE CATALOG logiflow;
-- ============================================================
-- GOLD: dim_filial (Apenas a versão mais atual de todos)
-- ============================================================
CREATE TABLE IF NOT EXISTS gold.dim_filial (
  branch_sk        BIGINT,
  nk_branch_id     STRING,
  branch_name      STRING,
  state            STRING,
  city             STRING,
  zip_code         STRING,
  street           STRING,
  effective_start  TIMESTAMP,
  effective_end    TIMESTAMP,
  row_hash         STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW dim_filial_stage AS
SELECT
  s.branch_sk,
  s.branch_id                                        AS nk_branch_id,
  s.branch_name,
  s.state,
  s.city,
  s.zip_code,
  s.street,
  s.effective_start,
  s.effective_end,
  sha2(concat_ws('||',
    coalesce(s.branch_name,''),
    coalesce(s.state,''),
    coalesce(s.city,''),
    coalesce(s.zip_code,''),
    coalesce(s.street,''),
    coalesce(date_format(s.effective_start,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(s.effective_end,  'yyyy-MM-dd HH:mm:ss'),'')
  ),256) AS row_hash
FROM silver.dim_filial_scd s
WHERE s.is_current = TRUE;

MERGE INTO gold.dim_filial t
USING dim_filial_stage s
ON t.nk_branch_id = s.nk_branch_id
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN
  UPDATE SET
    t.branch_sk       = s.branch_sk,
    t.branch_name     = s.branch_name,
    t.state           = s.state,
    t.city            = s.city,
    t.zip_code        = s.zip_code,
    t.street          = s.street,
    t.effective_start = s.effective_start,
    t.effective_end   = s.effective_end,
    t.row_hash        = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  branch_sk, nk_branch_id, branch_name, state, city, zip_code, street, effective_start, effective_end, row_hash
) VALUES (
  s.branch_sk, s.nk_branch_id, s.branch_name, s.state, s.city, s.zip_code, s.street, s.effective_start, s.effective_end, s.row_hash
);

-- O famoso "Desconhecido" (para não quebrar nada se faltar dado)
INSERT INTO gold.dim_filial
SELECT 0, '_UNKNOWN_', 'Desconhecida', NULL, NULL, NULL, NULL, TIMESTAMP('1900-01-01'), TIMESTAMP('9999-12-31'), sha2('_UNKNOWN_',256)
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_filial WHERE nk_branch_id = '_UNKNOWN_');

-- ============================================================
-- GOLD: dim_filial_scd (Cópia para o Range Join da Fato)
-- ============================================================
CREATE TABLE IF NOT EXISTS gold.dim_filial_scd (
  branch_sk        BIGINT,
  branch_id        STRING,
  branch_name      STRING,
  state            STRING,
  city             STRING,
  zip_code         STRING,
  street           STRING,
  effective_start  TIMESTAMP,
  effective_end    TIMESTAMP,
  is_current       BOOLEAN,
  row_hash         STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW dim_filial_scd_stage AS
SELECT
  s.branch_sk,
  s.branch_id,
  s.branch_name,
  s.state,
  s.city,
  s.zip_code,
  s.street,
  s.effective_start,
  s.effective_end,
  s.is_current,
  s.row_hash
FROM silver.dim_filial_scd s;

MERGE INTO gold.dim_filial_scd t
USING dim_filial_scd_stage s
ON t.branch_sk = s.branch_sk
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN UPDATE SET
  t.branch_id       = s.branch_id,
  t.branch_name     = s.branch_name,
  t.state           = s.state,
  t.city            = s.city,
  t.zip_code        = s.zip_code,
  t.street          = s.street,
  t.effective_start = s.effective_start,
  t.effective_end   = s.effective_end,
  t.is_current      = s.is_current,
  t.row_hash        = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  branch_sk, branch_id, branch_name, state, city, zip_code, street, effective_start, effective_end, is_current, row_hash
) VALUES (
  s.branch_sk, s.branch_id, s.branch_name, s.state, s.city, s.zip_code, s.street, s.effective_start, s.effective_end, s.is_current, s.row_hash
);
