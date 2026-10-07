USE CATALOG logiflow;

-- ============================================================
-- GOLD: dim_filiais_horarios
-- Fonte: silver.dim_filiais_horarios
-- Objetivo: Tabela de horários de funcionamento, consumida pelo PBI
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.dim_filiais_horarios (
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

CREATE OR REPLACE TEMP VIEW stage_gold_filiais_horarios AS
SELECT
  cod_filial,
  filial,
  hora_inicio,
  hora_primeiro_pedido,
  hora_almoco_inicio,
  hora_almoco_fim,
  hora_ultimo_pedido,
  hora_fim,
  total_hora_de_trabalho_sem_almoco,
  total_hora_de_trabalho_com_almoco,
  pausa_para_almoco,
  supervisor
FROM silver.dim_filiais_horarios;

-- Overwrite completo na gold para refletir a silver exatamente
INSERT OVERWRITE gold.dim_filiais_horarios
SELECT * FROM stage_gold_filiais_horarios;

-- Adicionando registro _UNKNOWN_
INSERT INTO gold.dim_filiais_horarios
SELECT 
  '_UNKNOWN_', 
  'Desconhecida', 
  TIMESTAMP('1899-12-30 09:00:00'),
  TIMESTAMP('1899-12-30 09:00:00'),
  TIMESTAMP('1899-12-30 12:00:00'),
  TIMESTAMP('1899-12-30 13:00:00'),
  TIMESTAMP('1899-12-30 18:00:00'),
  TIMESTAMP('1899-12-30 18:00:00'),
  TIMESTAMP('1899-12-30 09:00:00'),
  TIMESTAMP('1899-12-30 08:00:00'),
  FALSE,
  'Desconhecido';
