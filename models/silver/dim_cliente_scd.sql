USE CATALOG logiflow;
-- ============================================================
-- SILVER: dim_cliente_scd (Guarda o histórico das mudanças) garantindo que não há duplicidade
-- Fonte: bronze.OCRD
-- ============================================================

-- 1) Tabela alvo (inclui row_hash para idempotência)
CREATE TABLE IF NOT EXISTS silver.dim_cliente_scd (
  customer_sk      BIGINT GENERATED ALWAYS AS IDENTITY,
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

-- 2) Lendo os dados brutos e corrigindo  data
CREATE OR REPLACE TEMP VIEW stage_customers_raw AS
SELECT
  CardCode                        AS customer_id,
  CardName                        AS customer_name,
  LicTradNum                      AS tax_id,
  lower(E_Mail)                   AS email,
  upper(trim(State1))             AS state,
  City                            AS city,
  ZipCode                         AS zip_code,
  Address                         AS address,
  Phone1                          AS phone,
  validFor                        AS is_active,
  COALESCE(
    try_to_timestamp(UpdateDate, 'yyyy-MM-dd HH:mm:ss'),
    try_to_timestamp(CreateDate, 'yyyy-MM-dd HH:mm:ss')
  ) AS src_ts
FROM bronze.OCRD
WHERE CardCode IS NOT NULL;

-- 3) Se houver clientes repetidos, ficamos com o registro mais recente
CREATE OR REPLACE TEMP VIEW stage_customers_latest AS
SELECT
  customer_id,
  customer_name,
  tax_id,
  email,
  state,
  city,
  zip_code,
  address,
  phone,
  is_active,
  src_ts
FROM (
  SELECT
    s.*,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY src_ts DESC NULLS LAST,
               customer_name DESC
    ) AS rn
  FROM stage_customers_raw s
) z
WHERE rn = 1;

-- 4) Criando hash
CREATE OR REPLACE TEMP VIEW stage_customers_hash AS
SELECT
  customer_id,
  customer_name,
  tax_id,
  email,
  state,
  city,
  zip_code,
  address,
  phone,
  is_active,
  src_ts,
  sha2(concat_ws('||',
    coalesce(customer_name,''),
    coalesce(tax_id,''),
    coalesce(email,''),
    coalesce(state,''),
    coalesce(city,''),
    coalesce(zip_code,''),
    coalesce(address,''),
    coalesce(phone,''),
    coalesce(is_active,'')
  ), 256) AS source_hash
FROM stage_customers_latest;

-- 5) Expirar versões correntes que sofreram alteração
MERGE INTO silver.dim_cliente_scd AS tgt
USING stage_customers_hash AS src
ON  tgt.customer_id = src.customer_id
AND tgt.is_current  = TRUE
WHEN MATCHED AND tgt.row_hash <> src.source_hash THEN
  UPDATE SET
    tgt.effective_end = COALESCE(src.src_ts, current_timestamp()),
    tgt.is_current    = FALSE;

-- 6) Inserir primeira versão OU nova versão apenas quando necessário
INSERT INTO silver.dim_cliente_scd (
  customer_id, customer_name, tax_id, email, state, city, zip_code, address, phone, is_active,
  effective_start, effective_end, is_current, row_hash
)
SELECT
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
  COALESCE(s.src_ts, current_timestamp()) AS effective_start,
  TIMESTAMP('9999-12-31')                 AS effective_end,
  TRUE                                    AS is_current,
  s.source_hash                           AS row_hash
FROM stage_customers_hash s
LEFT JOIN silver.dim_cliente_scd c
  ON c.customer_id = s.customer_id AND c.is_current = TRUE
WHERE c.customer_id IS NULL           -- novo cliente
   OR c.row_hash <> s.source_hash;    -- Hash Alterado
