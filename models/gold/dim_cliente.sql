USE CATALOG logiflow;
-- ============================================================
-- GOLD: dim_cliente (Apenas a versão mais atual de todos)
-- ============================================================
CREATE TABLE IF NOT EXISTS gold.dim_cliente (
  customer_sk      BIGINT,          
  nk_customer_id   STRING,          
  customer_name    STRING,
  tax_id           STRING,
  email            STRING,
  state            STRING,
  city             STRING,
  zip_code         STRING,
  address          STRING,
  phone            STRING,
  is_active        STRING,
  effective_start  TIMESTAMP,
  effective_end    TIMESTAMP,
  row_hash         STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW dim_cliente_stage AS
SELECT
  s.customer_sk,
  s.customer_id                                      AS nk_customer_id,
  s.customer_name,
  s.tax_id,
  s.email,
  s.state,
  s.city,
  s.zip_code,
  s.address,
  s.phone,
  s.is_active,
  s.effective_start,
  s.effective_end,
  sha2(concat_ws('||',
    coalesce(s.customer_name,''),
    coalesce(s.tax_id,''),
    coalesce(s.email,''),
    coalesce(s.state,''),
    coalesce(s.city,''),
    coalesce(s.zip_code,''),
    coalesce(s.address,''),
    coalesce(s.phone,''),
    coalesce(s.is_active,''),
    coalesce(date_format(s.effective_start,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(s.effective_end,  'yyyy-MM-dd HH:mm:ss'),'')
  ),256) AS row_hash
FROM silver.dim_cliente_scd s
WHERE s.is_current = TRUE;

MERGE INTO gold.dim_cliente t
USING dim_cliente_stage s
ON t.nk_customer_id = s.nk_customer_id
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN
  UPDATE SET
    t.customer_sk     = s.customer_sk,
    t.customer_name   = s.customer_name,
    t.tax_id          = s.tax_id,
    t.email           = s.email,
    t.state           = s.state,
    t.city            = s.city,
    t.zip_code        = s.zip_code,
    t.address         = s.address,
    t.phone           = s.phone,
    t.is_active       = s.is_active,
    t.effective_start = s.effective_start,
    t.effective_end   = s.effective_end,
    t.row_hash        = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  customer_sk, nk_customer_id, customer_name, tax_id, email, state, city, zip_code, address, phone, is_active, effective_start, effective_end, row_hash
) VALUES (
  s.customer_sk, s.nk_customer_id, s.customer_name, s.tax_id, s.email, s.state, s.city, s.zip_code, s.address, s.phone, s.is_active, s.effective_start, s.effective_end, s.row_hash
);

-- O famoso "Desconhecido" (para não quebrar nada se faltar dado)
INSERT INTO gold.dim_cliente
SELECT 0, '_UNKNOWN_', 'Desconhecido', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, TIMESTAMP('1900-01-01'), TIMESTAMP('9999-12-31'), sha2('_UNKNOWN_',256)
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_cliente WHERE nk_customer_id = '_UNKNOWN_');
