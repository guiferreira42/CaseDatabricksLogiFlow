USE CATALOG logiflow;
-- =========================================================
-- SILVER: opkl1_clean
-- Fonte: bronze.OPKL1 (Itens do PickList)
-- =========================================================
CREATE TABLE IF NOT EXISTS silver.opkl1_clean (
  pick_list_id     STRING,
  pick_line_id     STRING,
  order_id         STRING,
  item_code        STRING,
  rel_quantity     DECIMAL(18,2),
  pick_quantity    DECIMAL(18,2),
  updated_at       TIMESTAMP,
  row_hash         STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW stage_opkl1 AS
SELECT
  AbsEntry AS pick_list_id,
  PickEntry AS pick_line_id,
  OrderEntry AS order_id,
  ItemCode AS item_code,
  CAST(regexp_replace(RelQtty, ',', '.') AS DECIMAL(18,2)) AS rel_quantity,
  CAST(regexp_replace(PickQtty, ',', '.') AS DECIMAL(18,2)) AS pick_quantity,
  current_timestamp() AS updated_at
FROM bronze.OPKL1
WHERE AbsEntry IS NOT NULL AND PickEntry IS NOT NULL;

CREATE OR REPLACE TEMP VIEW stage_opkl1_dedup AS
SELECT * FROM (
  SELECT
    s.*,
    ROW_NUMBER() OVER (
      PARTITION BY pick_list_id, pick_line_id
      ORDER BY updated_at DESC NULLS LAST
    ) AS rn
  FROM stage_opkl1 s
) z
WHERE rn = 1;

CREATE OR REPLACE TEMP VIEW stage_opkl1_final AS
SELECT
  *,
  sha2(concat_ws('||',
    coalesce(order_id,''),
    coalesce(item_code,''),
    cast(coalesce(rel_quantity,0) as string),
    cast(coalesce(pick_quantity,0) as string)
  ), 256) AS row_hash
FROM stage_opkl1_dedup;

MERGE INTO silver.opkl1_clean AS t
USING stage_opkl1_final AS s
ON t.pick_list_id = s.pick_list_id AND t.pick_line_id = s.pick_line_id
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN UPDATE SET
  t.order_id      = s.order_id,
  t.item_code     = s.item_code,
  t.rel_quantity  = s.rel_quantity,
  t.pick_quantity = s.pick_quantity,
  t.updated_at    = s.updated_at,
  t.row_hash      = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  pick_list_id, pick_line_id, order_id, item_code, rel_quantity, pick_quantity, updated_at, row_hash
) VALUES (
  s.pick_list_id, s.pick_line_id, s.order_id, s.item_code, s.rel_quantity, s.pick_quantity, s.updated_at, s.row_hash
);
