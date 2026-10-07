USE CATALOG logiflow;

CREATE TABLE IF NOT EXISTS silver.dim_data (
  data_sk    INT,
  date_id    INT,          -- yyyymmdd
  data       DATE,
  ano        INT,
  trimestre  INT,
  mes        INT,
  dia        INT,
  dia_semana INT,          -- 1=Seg ... 7=Dom
  nome_mes   STRING,
  mes_abrev  STRING,
  nome_dia   STRING
) USING DELTA;

-- Gera a série de datas dinamicamente de 2020 a 2030
CREATE OR REPLACE TEMP VIEW data_series AS
SELECT explode(sequence(DATE('2020-01-01'), DATE('2030-12-31'), INTERVAL 1 DAY)) AS data;

CREATE OR REPLACE TEMP VIEW dim_data_stage AS
SELECT
  CAST(date_format(data, 'yyyyMMdd') AS INT) AS data_sk,
  CAST(date_format(data, 'yyyyMMdd') AS INT) AS date_id,
  data,
  YEAR(data) AS ano,
  QUARTER(data) AS trimestre,
  MONTH(data) AS mes,
  DAY(data) AS dia,
  CASE WHEN dayofweek(data)=1 THEN 7 ELSE dayofweek(data)-1 END AS dia_semana,
  element_at(map(
    1,'janeiro', 2,'fevereiro', 3,'março', 4,'abril', 5,'maio', 6,'junho',
    7,'julho', 8,'agosto', 9,'setembro', 10,'outubro', 11,'novembro', 12,'dezembro'
  ), MONTH(data)) AS nome_mes,
  element_at(map(
    1,'jan', 2,'fev', 3,'mar', 4,'abr', 5,'mai', 6,'jun',
    7,'jul', 8,'ago', 9,'set', 10,'out', 11,'nov', 12,'dez'
  ), MONTH(data)) AS mes_abrev,
  element_at(map(
    1,'segunda', 2,'terça', 3,'quarta', 4,'quinta', 5,'sexta', 6,'sábado', 7,'domingo'
  ), CASE WHEN dayofweek(data)=1 THEN 7 ELSE dayofweek(data)-1 END) AS nome_dia
FROM data_series;

MERGE INTO silver.dim_data t
USING dim_data_stage s
ON t.data_sk = s.data_sk
WHEN NOT MATCHED THEN INSERT (
  data_sk, date_id, data, ano, trimestre, mes, dia, dia_semana, nome_mes, mes_abrev, nome_dia
) VALUES (
  s.data_sk, s.date_id, s.data, s.ano, s.trimestre, s.mes, s.dia, s.dia_semana, s.nome_mes, s.mes_abrev, s.nome_dia
);
