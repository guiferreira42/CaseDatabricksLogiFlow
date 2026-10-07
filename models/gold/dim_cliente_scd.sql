USE CATALOG logiflow;
-- ============================================================
-- GOLD: dim_cliente_scd (Cópia para o Range Join da Fato)
-- ============================================================
CREATE TABLE IF NOT EXISTS gold.dim_cliente_scd (
  customer_sk      BIGINT,
  customer_id      STRING,
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
  is_current       BOOLEAN,
  row_hash         STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW dim_cliente_scd_stage AS
SELECT
  s.customer_sk,
  s.customer_id,
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
  s.is_current,
  s.row_hash
FROM silver.dim_cliente_scd s;

MERGE INTO gold.dim_cliente_scd t
USING dim_cliente_scd_stage s
ON t.customer_sk = s.customer_sk
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN UPDATE SET
  t.customer_id     = s.customer_id,
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
  t.is_current      = s.is_current,
  t.row_hash        = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  customer_sk, customer_id, customer_name, tax_id, email, state, city, zip_code, address, phone, is_active, effective_start, effective_end, is_current, row_hash
) VALUES (
  s.customer_sk, s.customer_id, s.customer_name, s.tax_id, s.email, s.state, s.city, s.zip_code, s.address, s.phone, s.is_active, s.effective_start, s.effective_end, s.is_current, s.row_hash
);
