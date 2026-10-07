USE CATALOG logiflow;
-- =========================================================
-- SILVER: opkl_clean
-- Fonte: bronze.OPKL (Cabeçalho do PickList)
-- =========================================================
CREATE TABLE IF NOT EXISTS silver.opkl_clean (
  pick_list_id   STRING,
  pick_date      DATE,
  status         STRING,
  order_id       STRING,
  data_pedido    TIMESTAMP,
  customer_id    STRING,
  branch_id      STRING,
  separator_id   STRING,
  pronto_impressao TIMESTAMP,
  em_separacao   TIMESTAMP,
  pronto_conferencia TIMESTAMP,
  em_conferencia TIMESTAMP,
  conferido      TIMESTAMP,
  saida          TIMESTAMP,
  cod_transp     STRING,
  created_at     TIMESTAMP,
  row_hash       STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW stage_opkl AS
SELECT
  AbsEntry AS pick_list_id,
  COALESCE(
    try_to_timestamp(PickDate, 'yyyy-MM-dd HH:mm:ss'),
    try_to_timestamp(PickDate, 'yyyy-MM-dd')
  ) AS pick_ts,
  UPPER(TRIM(Status)) AS status,
  U_CodPedido AS order_id,
  try_to_timestamp(U_DataPedido, 'yyyy-MM-dd HH:mm:ss') AS data_pedido,
  U_CodCliente AS customer_id,
  U_Filial AS branch_id,
  U_IdSeparador AS separator_id,
  try_to_timestamp(U_ProntoParaImpressao, 'yyyy-MM-dd HH:mm:ss') AS pronto_impressao,
  try_to_timestamp(U_EmSeparacao, 'yyyy-MM-dd HH:mm:ss') AS em_separacao,
  try_to_timestamp(U_ProntoParaConferencia, 'yyyy-MM-dd HH:mm:ss') AS pronto_conferencia,
  try_to_timestamp(U_EmConferencia, 'yyyy-MM-dd HH:mm:ss') AS em_conferencia,
  try_to_timestamp(U_Conferido, 'yyyy-MM-dd HH:mm:ss') AS conferido,
  try_to_timestamp(U_Saida, 'yyyy-MM-dd HH:mm:ss') AS saida,
  U_CodTransp AS cod_transp,
  try_to_timestamp(UpdateDate, 'yyyy-MM-dd HH:mm:ss') AS update_date
FROM bronze.OPKL
WHERE AbsEntry IS NOT NULL;

CREATE OR REPLACE TEMP VIEW stage_opkl_dedup AS
SELECT
  pick_list_id,
  CAST(pick_ts AS DATE) AS pick_date,
  status,
  order_id,
  data_pedido,
  customer_id,
  branch_id,
  separator_id,
  pronto_impressao,
  em_separacao,
  pronto_conferencia,
  em_conferencia,
  conferido,
  saida,
  cod_transp,
  pick_ts AS created_at
FROM (
  SELECT
    s.*,
    ROW_NUMBER() OVER (
      PARTITION BY pick_list_id
      ORDER BY update_date DESC NULLS LAST, pick_ts DESC NULLS LAST
    ) AS rn
  FROM stage_opkl s
  WHERE pick_ts IS NOT NULL
) z
WHERE rn = 1;

CREATE OR REPLACE TEMP VIEW stage_opkl_final AS
SELECT
  pick_list_id,
  pick_date,
  status,
  order_id,
  data_pedido,
  customer_id,
  branch_id,
  separator_id,
  pronto_impressao,
  em_separacao,
  pronto_conferencia,
  em_conferencia,
  conferido,
  saida,
  cod_transp,
  created_at,
  sha2(concat_ws('||',
    coalesce(date_format(pick_date,'yyyy-MM-dd'),''),
    coalesce(status,''),
    coalesce(order_id,''),
    coalesce(date_format(data_pedido,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(customer_id,''),
    coalesce(branch_id,''),
    coalesce(separator_id,''),
    coalesce(date_format(pronto_impressao,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(em_separacao,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(pronto_conferencia,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(em_conferencia,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(conferido,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(saida,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(cod_transp,'')
  ), 256) AS row_hash
FROM stage_opkl_dedup;

MERGE INTO silver.opkl_clean AS t
USING stage_opkl_final AS s
ON t.pick_list_id = s.pick_list_id
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN UPDATE SET
  t.pick_date  = s.pick_date,
  t.status     = s.status,
  t.order_id   = s.order_id,
  t.data_pedido = s.data_pedido,
  t.customer_id = s.customer_id,
  t.branch_id  = s.branch_id,
  t.separator_id = s.separator_id,
  t.pronto_impressao = s.pronto_impressao,
  t.em_separacao = s.em_separacao,
  t.pronto_conferencia = s.pronto_conferencia,
  t.em_conferencia = s.em_conferencia,
  t.conferido = s.conferido,
  t.saida = s.saida,
  t.cod_transp = s.cod_transp,
  t.created_at = s.created_at,
  t.row_hash   = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  pick_list_id, pick_date, status, order_id, data_pedido, customer_id, branch_id, separator_id, pronto_impressao, em_separacao, pronto_conferencia, em_conferencia, conferido, saida, cod_transp, created_at, row_hash
)
VALUES (
  s.pick_list_id, s.pick_date, s.status, s.order_id, s.data_pedido, s.customer_id, s.branch_id, s.separator_id, s.pronto_impressao, s.em_separacao, s.pronto_conferencia, s.em_conferencia, s.conferido, s.saida, s.cod_transp, s.created_at, s.row_hash
);
