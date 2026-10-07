USE CATALOG logiflow;

-- ============================================================
-- SILVER: dim_filiais_horarios
-- Fonte: silver.dim_empresas
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.dim_filiais_horarios (
  cod_filial                       STRING,
  filial                           STRING,
  hora_inicio                      TIMESTAMP,
  hora_primeiro_pedido             TIMESTAMP,
  hora_almoco_inicio               TIMESTAMP,
  hora_almoco_fim                  TIMESTAMP,
  hora_ultimo_pedido               TIMESTAMP,
  hora_fim                         TIMESTAMP,
  total_hora_de_trabalho_sem_almoco TIMESTAMP,
  total_hora_de_trabalho_com_almoco TIMESTAMP,
  pausa_para_almoco                BOOLEAN,
  supervisor                       STRING
) USING DELTA;

CREATE OR REPLACE TEMP VIEW stage_filiais_horarios AS
SELECT
  cod_filial,
  nome AS filial,
  TIMESTAMP('1899-12-30 09:00:00') AS hora_inicio,
  TIMESTAMP('1899-12-30 09:30:00') AS hora_primeiro_pedido,
  TIMESTAMP('1899-12-30 12:00:00') AS hora_almoco_inicio,
  TIMESTAMP('1899-12-30 13:00:00') AS hora_almoco_fim,
  TIMESTAMP('1899-12-30 17:30:00') AS hora_ultimo_pedido,
  TIMESTAMP('1899-12-30 18:00:00') AS hora_fim,
  TIMESTAMP('1899-12-30 09:00:00') AS total_hora_de_trabalho_sem_almoco,
  TIMESTAMP('1899-12-30 08:00:00') AS total_hora_de_trabalho_com_almoco,
  CASE WHEN porte = 'Pequena' THEN TRUE ELSE FALSE END AS pausa_para_almoco,
  supervisor
FROM silver.dim_empresas
WHERE is_current = TRUE AND cod_filial <> '_UNKNOWN_';

INSERT OVERWRITE silver.dim_filiais_horarios
SELECT * FROM stage_filiais_horarios;
