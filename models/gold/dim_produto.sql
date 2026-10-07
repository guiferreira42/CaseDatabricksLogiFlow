USE CATALOG logiflow;
-- ============================================
-- GOLD: dim_produto (NK = product_id)
-- ============================================
CREATE TABLE IF NOT EXISTS gold.dim_produto (
  product_sk    BIGINT GENERATED ALWAYS AS IDENTITY,
  nk_product_id STRING,
  product_name  STRING,
  category_id   STRING,
  sales_unit    STRING,
  buy_unit      STRING,
  weight        DECIMAL(18,3),
  length        DECIMAL(18,2),
  width         DECIMAL(18,2),
  height        DECIMAL(18,2),
  barcode       STRING,
  is_active     STRING,
  created_at    TIMESTAMP,
  row_hash      STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW dim_produto_stage AS
SELECT
  product_id      AS nk_product_id,
  product_name,
  category_id,
  sales_unit,
  buy_unit,
  weight,
  length,
  width,
  height,
  barcode,
  is_active,
  created_at,
  row_hash
FROM silver.dim_produto;

MERGE INTO gold.dim_produto t
USING dim_produto_stage s
ON t.nk_product_id = s.nk_product_id
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
  nk_product_id, product_name, category_id, sales_unit, buy_unit, weight, length, width, height, barcode, is_active, created_at, row_hash
) VALUES (
  s.nk_product_id, s.product_name, s.category_id, s.sales_unit, s.buy_unit, s.weight, s.length, s.width, s.height, s.barcode, s.is_active, s.created_at, s.row_hash
);

-- O famoso "Desconhecido" (para não quebrar nada se faltar dado) (para fatos sem produto conhecido)
INSERT INTO gold.dim_produto (nk_product_id, product_name, row_hash)
SELECT '_UNKNOWN_', 'Desconhecido', sha2('_UNKNOWN_',256)
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_produto WHERE nk_product_id = '_UNKNOWN_');
