USE CATALOG logiflow;
CREATE TABLE IF NOT EXISTS gold.dim_data (
  data_sk    INT,
  date_id    INT,
  data       DATE,
  ano        INT,
  trimestre  INT,
  mes        INT,
  dia        INT,
  dia_semana INT,
  nome_mes   STRING,
  mes_abrev  STRING,
  nome_dia   STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW dim_data_stage AS
SELECT * FROM silver.dim_data;

MERGE INTO gold.dim_data t
USING dim_data_stage s
ON t.data_sk = s.data_sk
WHEN NOT MATCHED THEN INSERT (
  data_sk, date_id, data, ano, trimestre, mes, dia, dia_semana, nome_mes, mes_abrev, nome_dia
) VALUES (
  s.data_sk, s.date_id, s.data, s.ano, s.trimestre, s.mes, s.dia, s.dia_semana, s.nome_mes, s.mes_abrev, s.nome_dia
);
