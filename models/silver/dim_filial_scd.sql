USE CATALOG logiflow;
-- ============================================================
-- SILVER: dim_filial_scd (Guarda o histórico das mudanças) garantindo que não há duplicidade
-- Fonte: bronze.OWHS
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.dim_filial_scd (
  branch_sk        BIGINT GENERATED ALWAYS AS IDENTITY,
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

-- Passo 1: Trazendo os dados brutos da origem
CREATE OR REPLACE TEMP VIEW stage_branches_raw AS
SELECT
  WhsCode                         AS branch_id,
  WhsName                         AS branch_name,
  upper(trim(State))              AS state,
  City                            AS city,
  ZipCode                         AS zip_code,
  Street                          AS street,
  current_timestamp()             AS src_ts
FROM bronze.OWHS
WHERE WhsCode IS NOT NULL;

-- Dedup
CREATE OR REPLACE TEMP VIEW stage_branches_latest AS
SELECT * FROM (
  SELECT
    s.*,
    ROW_NUMBER() OVER (
      PARTITION BY branch_id
      ORDER BY src_ts DESC NULLS LAST
    ) AS rn
  FROM stage_branches_raw s
) z
WHERE rn = 1;

-- Criando Hash
CREATE OR REPLACE TEMP VIEW stage_branches_hash AS
SELECT
  branch_id,
  branch_name,
  state,
  city,
  zip_code,
  street,
  src_ts,
  sha2(concat_ws('||',
    coalesce(branch_name,''),
    coalesce(state,''),
    coalesce(city,''),
    coalesce(zip_code,''),
    coalesce(street,'')
  ), 256) AS source_hash
FROM stage_branches_latest;

-- Se o dado mudou, fechamos a versão antiga (ela vira passado)
MERGE INTO silver.dim_filial_scd AS tgt
USING stage_branches_hash AS src
ON  tgt.branch_id = src.branch_id
AND tgt.is_current  = TRUE
WHEN MATCHED AND tgt.row_hash <> src.source_hash THEN
  UPDATE SET
    tgt.effective_end = COALESCE(src.src_ts, current_timestamp()),
    tgt.is_current    = FALSE;

-- Guardando o que é novo (itens novos ou recém atualizados)
INSERT INTO silver.dim_filial_scd (
  branch_id, branch_name, state, city, zip_code, street,
  effective_start, effective_end, is_current, row_hash
)
SELECT
  s.branch_id,
  s.branch_name,
  s.state,
  s.city,
  s.zip_code,
  s.street,
  COALESCE(s.src_ts, current_timestamp()) AS effective_start,
  TIMESTAMP('9999-12-31')                 AS effective_end,
  TRUE                                    AS is_current,
  s.source_hash                           AS row_hash
FROM stage_branches_hash s
LEFT JOIN silver.dim_filial_scd c
  ON c.branch_id = s.branch_id AND c.is_current = TRUE
WHERE c.branch_id IS NULL 
   OR c.row_hash <> s.source_hash;
