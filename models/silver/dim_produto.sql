USE CATALOG logiflow;
-- ============================================================
-- SILVER: dim_produto
-- Fonte: bronze.OITM
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.dim_produto (
  product_id       STRING,
  product_name     STRING,
  category_id      STRING,
  sales_unit       STRING,
  buy_unit         STRING,
  weight           DECIMAL(18,3),
  length           DECIMAL(18,2),
  width            DECIMAL(18,2),
  height           DECIMAL(18,2),
  barcode          STRING,
  is_active        STRING,
  created_at       TIMESTAMP,
  row_hash         STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW stage_products_raw AS
SELECT
  ItemCode                        AS product_id,
  ItemName                        AS product_name,
  ItmsGrpCod                      AS category_id,
  SalUnitMsr                      AS sales_unit,
  BuyUnitMsr                      AS buy_unit,
  CAST(SWeight1 AS DECIMAL(18,3)) AS weight,
  CAST(SLength1 AS DECIMAL(18,2)) AS length,
  CAST(SWidth1 AS DECIMAL(18,2))  AS width,
  CAST(SHeight1 AS DECIMAL(18,2)) AS height,
  CodeBars                        AS barcode,
  validFor                        AS is_active,
  COALESCE(
    try_to_timestamp(CreateDate, 'yyyy-MM-dd HH:mm:ss'),
    try_to_timestamp(CreateDate, 'yyyy-MM-dd')
  ) AS created_at
FROM bronze.OITM
WHERE ItemCode IS NOT NULL;

-- Dedup
CREATE OR REPLACE TEMP VIEW stage_products_dedup AS
SELECT * FROM (
  SELECT
    s.*,
    ROW_NUMBER() OVER (
      PARTITION BY product_id
      ORDER BY created_at DESC NULLS LAST
    ) AS rn
  FROM stage_products_raw s
) z
WHERE rn = 1;

-- Hash Idempotente
CREATE OR REPLACE TEMP VIEW stage_products_final AS
SELECT
  *,
  sha2(concat_ws('||',
    coalesce(product_name,''),
    coalesce(category_id,''),
    coalesce(sales_unit,''),
    coalesce(buy_unit,''),
    cast(coalesce(weight,0) as string),
    cast(coalesce(length,0) as string),
    cast(coalesce(width,0) as string),
    cast(coalesce(height,0) as string),
    coalesce(barcode,''),
    coalesce(is_active,'')
  ), 256) AS row_hash
FROM stage_products_dedup;

-- Merge
MERGE INTO silver.dim_produto AS t
USING stage_products_final AS s
ON  t.product_id = s.product_id
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN UPDATE SET
  t.product_name = s.product_name,
  t.category_id  = s.category_id,
  t.sales_unit   = s.sales_unit,
  t.buy_unit     = s.buy_unit,
  t.weight       = s.weight,
  t.length       = s.length,
  t.width        = s.width,
  t.height       = s.height,
  t.barcode      = s.barcode,
  t.is_active    = s.is_active,
  t.created_at   = s.created_at,
  t.row_hash     = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  product_id, product_name, category_id, sales_unit, buy_unit, weight, length, width, height, barcode, is_active, created_at, row_hash
) VALUES (
  s.product_id, s.product_name, s.category_id, s.sales_unit, s.buy_unit, s.weight, s.length, s.width, s.height, s.barcode, s.is_active, s.created_at, s.row_hash
);
