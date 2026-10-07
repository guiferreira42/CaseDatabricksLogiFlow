USE CATALOG logiflow;

CREATE TABLE IF NOT EXISTS gold.fact_picklists (
  CodPickList          STRING,
  DataPickList         TIMESTAMP,
  CodPedido            STRING,
  DataPedido           TIMESTAMP,
  NF                   STRING,
  DataNota             TIMESTAMP,
  DocNumNF             STRING,
  Volume               BIGINT,
  PesoBruto            DECIMAL(18,4),
  CodCliente           STRING,
  TipoEstoque          STRING,
  Filial               STRING,
  QtdSKU               BIGINT,
  QtdPecas             DECIMAL(18,2),
  QtdSN                BIGINT,
  ProntoParaImpressao  TIMESTAMP,
  IdSeparador          STRING,
  UserSeparador        STRING,
  EmSeparacao          TIMESTAMP,
  ProntoParaConferencia TIMESTAMP,
  IdConferente         STRING,
  UserConferente       STRING,
  EmConferencia        TIMESTAMP,
  Conferido            TIMESTAMP,
  IdExpedidor          STRING,
  UserExpedidor        STRING,
  Saida                TIMESTAMP,
  IdRomaneio           STRING,
  DataRomaneio         TIMESTAMP,
  Cancelado            STRING,
  StatusDocumento      STRING,
  TipoFrete            STRING,
  CodTransp            STRING,
  Supervisor           STRING,
  Regra_PedidoFracionado STRING,
  Regra_SKU_SN         STRING,
  Regra_Retira_NossoCarro STRING,
  ProntoParaImpressaoAjustado TIMESTAMP,
  sla_segundos         BIGINT,
  sla_HHMMSS           TIMESTAMP,
  Atualizado           TIMESTAMP,
  fk_data_sk           INT,
  fk_empresa_sk        BIGINT,
  fk_cliente_sk        BIGINT,
  row_hash             STRING
) USING DELTA
PARTITIONED BY (fk_data_sk);

CREATE OR REPLACE TEMP VIEW fact_stage AS
WITH 
pk1_agg AS (
  SELECT 
    pk1.pick_list_id,
    COUNT(DISTINCT pk1.item_code) AS QtdSKU,
    SUM(pk1.pick_quantity) AS QtdPecas,
    0 AS QtdSN,
    SUM(COALESCE(pk1.pick_quantity, 0) * COALESCE(p.weight, 0)) AS PesoBruto
  FROM silver.opkl1_clean pk1
  LEFT JOIN gold.dim_produto p ON pk1.item_code = p.nk_product_id
  GROUP BY pk1.pick_list_id
),
base AS (
  SELECT
    pk.pick_list_id AS CodPickList,
    pk.pick_date AS DataPickList,
    pk.order_id AS CodPedido,
    pk.data_pedido AS DataPedido,
    NULL AS NF,
    NULL AS DataNota,
    NULL AS DocNumNF,
    1 AS Volume,
    COALESCE(pk1_agg.PesoBruto, 0) AS PesoBruto,
    pk.customer_id AS CodCliente,
    'M' AS TipoEstoque,
    pk.branch_id AS Filial,
    COALESCE(pk1_agg.QtdSKU, 0) AS QtdSKU,
    COALESCE(pk1_agg.QtdPecas, 0) AS QtdPecas,
    COALESCE(pk1_agg.QtdSN, 0) AS QtdSN,
    -- Estimativa para datas que faltam na raw data
    pk.pronto_impressao AS ProntoParaImpressao,
    pk.separator_id AS IdSeparador,
    pk.separator_id AS UserSeparador,
    pk.em_separacao AS EmSeparacao,
    pk.pronto_conferencia AS ProntoParaConferencia,
    pk.separator_id AS IdConferente,
    pk.separator_id AS UserConferente,
    pk.em_conferencia AS EmConferencia,
    pk.conferido AS Conferido,
    pk.separator_id AS IdExpedidor,
    pk.separator_id AS UserExpedidor,
    pk.saida AS Saida,
    NULL AS IdRomaneio,
    NULL AS DataRomaneio,
    CASE WHEN pk.status = 'C' THEN 'Y' ELSE 'N' END AS Cancelado,
    pk.status AS StatusDocumento,
    '9' AS TipoFrete,
    pk.cod_transp AS CodTransp,
    e.supervisor AS Supervisor,
    'Considerar' AS Regra_PedidoFracionado,
    'Considerar' AS Regra_SKU_SN,
    'Considerar' AS Regra_Retira_NossoCarro,
    pk.pronto_impressao AS ProntoParaImpressaoAjustado,
    unix_timestamp(pk.pronto_conferencia) - unix_timestamp(pk.em_separacao) AS sla_segundos,
    NULL AS sla_HHMMSS,
    current_timestamp() AS Atualizado,
    dt.data_sk AS fk_data_sk,
    COALESCE(e.empresa_sk, 0) AS fk_empresa_sk,
    COALESCE(c.customer_sk, 0) AS fk_cliente_sk
  FROM silver.opkl_clean pk
  LEFT JOIN pk1_agg ON pk.pick_list_id = pk1_agg.pick_list_id
  LEFT JOIN silver.dim_empresas e 
    ON pk.branch_id = e.cod_filial 
    AND pk.pick_date >= CAST(e.effective_start AS DATE) 
    AND pk.pick_date < CAST(COALESCE(e.effective_end, '9999-12-31') AS DATE)
  LEFT JOIN silver.dim_cliente_scd c
    ON pk.customer_id = c.customer_id
    AND pk.pick_date >= CAST(c.effective_start AS DATE)
    AND pk.pick_date < CAST(COALESCE(c.effective_end, '9999-12-31') AS DATE)
  LEFT JOIN gold.dim_data dt ON dt.data = pk.pick_date
  WHERE pk.pick_date >= '2026-01-01'
)
SELECT
  *,
  sha2(concat_ws('||',
    CodPickList,
    cast(fk_data_sk as string),
    cast(fk_empresa_sk as string),
    cast(fk_cliente_sk as string),
    CodPedido,
    coalesce(date_format(DataPedido,'yyyy-MM-dd HH:mm:ss'),''),
    CodCliente,
    Filial,
    StatusDocumento,
    cast(QtdPecas as string),
    cast(QtdSKU as string),
    coalesce(date_format(ProntoParaImpressao,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(EmSeparacao,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(ProntoParaConferencia,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(EmConferencia,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(Conferido,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(date_format(Saida,'yyyy-MM-dd HH:mm:ss'),''),
    coalesce(CodTransp,'')
  ),256) AS row_hash
FROM base;

MERGE INTO gold.fact_picklists t
USING fact_stage s
ON t.CodPickList = s.CodPickList
WHEN MATCHED AND (t.row_hash IS NULL OR t.row_hash <> s.row_hash) THEN UPDATE SET
  t.DataPickList = s.DataPickList,
  t.CodPedido = s.CodPedido,
  t.DataPedido = s.DataPedido,
  t.NF = s.NF,
  t.DataNota = s.DataNota,
  t.DocNumNF = s.DocNumNF,
  t.Volume = s.Volume,
  t.PesoBruto = s.PesoBruto,
  t.CodCliente = s.CodCliente,
  t.TipoEstoque = s.TipoEstoque,
  t.Filial = s.Filial,
  t.QtdSKU = s.QtdSKU,
  t.QtdPecas = s.QtdPecas,
  t.QtdSN = s.QtdSN,
  t.ProntoParaImpressao = s.ProntoParaImpressao,
  t.IdSeparador = s.IdSeparador,
  t.UserSeparador = s.UserSeparador,
  t.EmSeparacao = s.EmSeparacao,
  t.ProntoParaConferencia = s.ProntoParaConferencia,
  t.IdConferente = s.IdConferente,
  t.UserConferente = s.UserConferente,
  t.EmConferencia = s.EmConferencia,
  t.Conferido = s.Conferido,
  t.IdExpedidor = s.IdExpedidor,
  t.UserExpedidor = s.UserExpedidor,
  t.Saida = s.Saida,
  t.IdRomaneio = s.IdRomaneio,
  t.DataRomaneio = s.DataRomaneio,
  t.Cancelado = s.Cancelado,
  t.StatusDocumento = s.StatusDocumento,
  t.TipoFrete = s.TipoFrete,
  t.CodTransp = s.CodTransp,
  t.Supervisor = s.Supervisor,
  t.Regra_PedidoFracionado = s.Regra_PedidoFracionado,
  t.Regra_SKU_SN = s.Regra_SKU_SN,
  t.Regra_Retira_NossoCarro = s.Regra_Retira_NossoCarro,
  t.ProntoParaImpressaoAjustado = s.ProntoParaImpressaoAjustado,
  t.sla_segundos = s.sla_segundos,
  t.sla_HHMMSS = s.sla_HHMMSS,
  t.Atualizado = s.Atualizado,
  t.fk_data_sk = s.fk_data_sk,
  t.fk_empresa_sk = s.fk_empresa_sk,
  t.fk_cliente_sk = s.fk_cliente_sk,
  t.row_hash = s.row_hash
WHEN NOT MATCHED THEN INSERT (
  CodPickList, DataPickList, CodPedido, DataPedido, NF, DataNota, DocNumNF, Volume, PesoBruto, CodCliente, TipoEstoque, Filial, QtdSKU, QtdPecas, QtdSN, ProntoParaImpressao, IdSeparador, UserSeparador, EmSeparacao, ProntoParaConferencia, IdConferente, UserConferente, EmConferencia, Conferido, IdExpedidor, UserExpedidor, Saida, IdRomaneio, DataRomaneio, Cancelado, StatusDocumento, TipoFrete, CodTransp, Supervisor, Regra_PedidoFracionado, Regra_SKU_SN, Regra_Retira_NossoCarro, ProntoParaImpressaoAjustado, sla_segundos, sla_HHMMSS, Atualizado, fk_data_sk, fk_empresa_sk, fk_cliente_sk, row_hash
) VALUES (
  s.CodPickList, s.DataPickList, s.CodPedido, s.DataPedido, s.NF, s.DataNota, s.DocNumNF, s.Volume, s.PesoBruto, s.CodCliente, s.TipoEstoque, s.Filial, s.QtdSKU, s.QtdPecas, s.QtdSN, s.ProntoParaImpressao, s.IdSeparador, s.UserSeparador, s.EmSeparacao, s.ProntoParaConferencia, s.IdConferente, s.UserConferente, s.EmConferencia, s.Conferido, s.IdExpedidor, s.UserExpedidor, s.Saida, s.IdRomaneio, s.DataRomaneio, s.Cancelado, s.StatusDocumento, s.TipoFrete, s.CodTransp, s.Supervisor, s.Regra_PedidoFracionado, s.Regra_SKU_SN, s.Regra_Retira_NossoCarro, s.ProntoParaImpressaoAjustado, s.sla_segundos, s.sla_HHMMSS, s.Atualizado, s.fk_data_sk, s.fk_empresa_sk, s.fk_cliente_sk, s.row_hash
);
