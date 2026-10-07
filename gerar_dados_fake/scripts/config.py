"""
Parâmetros do simulador LogiFlow (Papelaria - SAP B1).
"""
import os
from datetime import datetime

# ============================================================
# Caminhos
# ============================================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASES_DIR = os.path.join(BASE_DIR, 'bases')

# ============================================================
# Reprodutibilidade
# ------------------------------------------------------------
# Cada dia é gerado com uma semente própria (SEED + dia). Assim, rodar o
# gerador amanhã produz exatamente o mesmo histórico + o novo dia, e os
# documentos "em andamento" evoluem de status (simula extrações diárias / CDC).
# ============================================================
SEED = 42

# ============================================================
# Modo de Execução e Databricks
# ============================================================
# MODE: 'LOCAL' ou 'DATABRICKS'
#   LOCAL: Salva arquivos .csv na pasta local 'bases/'
#   DATABRICKS: Salva arquivos .csv diretamente em um Volume no Databricks (Bronze)
MODE = 'DATABRICKS'

DATABRICKS_CATALOG = 'logiflow'
DATABRICKS_SCHEMA_BRONZE = 'bronze'
DATABRICKS_VOLUME_BRONZE = 'raw_data'

# ============================================================
# Período
# ============================================================
DATA_INICIO = datetime(2026, 1, 1)
DATA_FIM_ANO = datetime.now()
DATA_CORTE = DATA_FIM_ANO 

# Modo de extração das tabelas transacionais
#   FULL        -> extrai tudo desde DATA_INICIO (primeira carga)
#   INCREMENTAL -> extrai somente documentos com UpdateDate nos últimos N dias
MODO_EXTRACAO = 'FULL'
JANELA_INCREMENTAL_DIAS = 35

# ============================================================
# Volumes (dados mestres)
# ============================================================
QTD_CLIENTES = 50000
QTD_PRODUTOS = 10000
QTD_OPERADORES = 500
QTD_TRANSPORTADORAS = 20
SUPERVISORES_POR_REGIAO = 4

# ============================================================
# Geografia: 1 filial por UF ("Flow" + UF)
# ============================================================
REGIOES = {
    'Norte':        ['AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO'],
    'Nordeste':     ['AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE'],
    'Centro-Oeste': ['DF', 'GO', 'MT', 'MS'],
    'Sudeste':      ['ES', 'MG', 'RJ', 'SP'],
    'Sul':          ['PR', 'RS', 'SC'],
}
UF_REGIAO = {uf: reg for reg, ufs in REGIOES.items() for uf in ufs}
ESTADOS = sorted(UF_REGIAO.keys())

UF_NOME = {
    'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas', 'BA': 'Bahia',
    'CE': 'Ceará', 'DF': 'Distrito Federal', 'ES': 'Espírito Santo', 'GO': 'Goiás',
    'MA': 'Maranhão', 'MT': 'Mato Grosso', 'MS': 'Mato Grosso do Sul', 'MG': 'Minas Gerais',
    'PA': 'Pará', 'PB': 'Paraíba', 'PR': 'Paraná', 'PE': 'Pernambuco', 'PI': 'Piauí',
    'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte', 'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia', 'RR': 'Roraima', 'SC': 'Santa Catarina', 'SP': 'São Paulo',
    'SE': 'Sergipe', 'TO': 'Tocantins',
}

# Peso de demanda por UF
PESO_DEMANDA_UF = {
    'SP': 15.0, 'RJ': 5.5, 'MG': 5.0, 'PR': 3.2, 'RS': 3.0, 'BA': 3.0, 'SC': 2.6,
    'PE': 2.2, 'DF': 2.2, 'CE': 2.0, 'GO': 2.0, 'PA': 1.5, 'ES': 1.4, 'AM': 1.2,
    'MT': 1.1, 'MS': 1.0, 'MA': 0.9, 'PB': 0.8, 'RN': 0.8, 'AL': 0.7, 'PI': 0.6,
    'SE': 0.6, 'RO': 0.6, 'TO': 0.5, 'AC': 0.35, 'AP': 0.3, 'RR': 0.3,
}

# Fator de quadro de pessoal (operadores por pedido relativo à rede).
# < 1 = filial enxuta (gargalo)  |  > 1 = filial bem dimensionada
# CAUSA -> Flow RJ e Flow BA têm alta demanda e quadro enxuto => maior espera para separar.
FATOR_QUADRO_UF = {'SP': 1.15, 'DF': 1.20, 'RJ': 0.60, 'BA': 0.70, 'AM': 0.80}

# Porte da filial a partir do peso de demanda
def porte_por_peso(peso):
    if peso >= 4.0:
        return 'Grande'
    if peso >= 1.5:
        return 'Media'
    return 'Pequena'

# Posições de picking (endereços) por porte -> distância média de deslocamento
POSICOES_PICKING = {'Grande': (8000, 12000), 'Media': (3000, 5000), 'Pequena': (800, 1500)}

# Horários operacionais por porte (tabela WHS_SCHEDULE - fora do SAP)
HORARIOS_POR_PORTE = {
    #            Inicio    PrimeiroPed AlmocoIni AlmocoFim UltimoPed  Fim      PausaAlmoco
    'Grande':  ('07:00:00', '07:30:00', '12:00:00', '13:00:00', '18:30:00', '19:00:00', 'N'),
    'Media':   ('08:00:00', '08:30:00', '12:00:00', '13:00:00', '17:30:00', '18:00:00', 'N'),
    'Pequena': ('08:12:00', '08:42:00', '12:00:00', '13:00:00', '17:42:00', '18:00:00', 'Y'),
}

# Janelas de coleta das transportadoras (romaneio) por porte
JANELAS_COLETA = {
    'Grande': ['10:30:00', '14:00:00', '17:30:00'],
    'Media': ['11:00:00', '16:30:00'],
    'Pequena': ['16:00:00'],
}

# ============================================================
# Produtos (papelaria)
# ============================================================
# Grupo (OITB) -> (Categoria, faixa de preço R$, faixa de peso kg, unidade, fator de manuseio)
GRUPOS_PRODUTO = {
    101: ('Papéis',               'Papéis',                 (22.0, 45.0),  (2.20, 2.60), 'RM', 1.6),
    102: ('Cadernos',             'Papelaria Escolar',      (8.0, 45.0),   (0.25, 1.10), 'UN', 1.1),
    103: ('Canetas',              'Escrita',                (1.5, 25.0),   (0.01, 0.04), 'UN', 0.6),
    104: ('Lápis e Lapiseiras',   'Escrita',                (0.8, 18.0),   (0.01, 0.05), 'UN', 0.6),
    105: ('Marcadores',           'Escrita',                (3.0, 18.0),   (0.02, 0.06), 'UN', 0.7),
    106: ('Borrachas e Corretivos','Papelaria Escolar',     (0.8, 9.0),    (0.01, 0.05), 'UN', 0.6),
    107: ('Réguas e Geometria',   'Papelaria Escolar',      (2.0, 15.0),   (0.02, 0.15), 'UN', 0.8),
    108: ('Mochilas',             'Mochilas e Acessórios',  (60.0, 350.0), (0.60, 1.60), 'UN', 1.8),
    109: ('Estojos',              'Mochilas e Acessórios',  (15.0, 90.0),  (0.10, 0.40), 'UN', 1.0),
    110: ('Calculadoras',         'Eletrônicos',            (25.0, 180.0), (0.10, 0.45), 'UN', 1.3),
    111: ('Colas e Adesivos',     'Escritório',             (3.0, 20.0),   (0.04, 0.30), 'UN', 0.8),
    112: ('Pastas e Arquivos',    'Escritório',             (4.0, 30.0),   (0.08, 0.60), 'UN', 0.9),
    113: ('Agendas',              'Escritório',             (20.0, 70.0),  (0.25, 0.60), 'UN', 1.0),
    114: ('Tesouras e Estiletes', 'Escritório',             (5.0, 30.0),   (0.03, 0.15), 'UN', 0.8),
}
GRUPOS_VOLTA_AS_AULAS = {102, 104, 106, 107, 108, 109}
MARCAS = ['Tilibra', 'Faber-Castell', 'BIC', 'Pilot', 'Stabilo', 'Chamex', 'Report', 'Jandaia',
          'Foroni', 'Acrilex', 'Maped', 'Casio', 'Dello', 'Compactor', 'Cis', 'Leo&Leo', 'Molin', 'Pentel']

# ============================================================
# Clientes (OCRD.GroupCode)
# ============================================================
# GroupCode -> (nome, % da base, faixa linhas por pedido, faixa qtd por linha)
GRUPOS_CLIENTE = {
    100: ('Varejo Papelaria', 0.45, (2, 12), (5, 60)),
    101: ('Escolas',          0.15, (4, 25), (10, 200)),
    102: ('Corporativo',      0.20, (2, 15), (2, 50)),
    103: ('Governo',          0.05, (5, 20), (20, 300)),
    104: ('E-commerce',       0.15, (1, 4),  (1, 5)),
}
PROB_CLIENTE_CRIADO_EM_2026 = 0.05
PROB_CLIENTE_BLOQUEADO = 0.03
PROB_CLIENTE_MUDA_ENDERECO = 0.06      # gera nova versão (SCD2)
PROB_MUDANCA_E_DE_UF = 0.30            # das mudanças, quantas trocam de estado

# ============================================================
# Pedidos e sazonalidade
# ============================================================
PEDIDOS_POR_MES = 10000
FATOR_DIA_SEMANA = {0: 1.30, 1: 1.10, 2: 1.05, 3: 1.00, 4: 0.90, 5: 0.20, 6: 0.08}
FATOR_MES = {1: 1.35, 2: 1.45, 3: 1.05, 4: 0.90, 5: 0.90, 6: 0.90,
             7: 1.10, 8: 0.95, 9: 0.90, 10: 0.95, 11: 1.10, 12: 0.80}
FATOR_FERIADO = 0.10
FATOR_FIM_DE_MES = 1.20               # últimos 3 dias úteis
FATOR_BLACK_FRIDAY = 1.80             # semana da Black Friday
BLACK_FRIDAY = datetime(2026, 11, 27)
BOOST_VOLTA_AS_AULAS = 2.0            # peso extra dos grupos escolares em jan/fev/jul

# ============================================================
# Operação (tempos em minutos)
# ============================================================
ESPERA_BASE_SEPARACAO = {'Grande': 12, 'Media': 20, 'Pequena': 30}
ESPERA_BASE_CONFERENCIA = 6
ELASTICIDADE_CARGA = 1.3              # espera ~ (carga do dia) ^ elasticidade
PROB_OPERADOR_AUSENTE = 0.04

# ============================================================
# Cenários (probabilidades)
# ============================================================
PROB_CANCELAMENTO_ANTES_PICKING = 0.020
PROB_CANCELAMENTO_APOS_PICKING = 0.008
PROB_FALTA_ESTOQUE_LINHA = 0.025
PROB_FALTA_CONHECIDA_NA_RESERVA = 0.50   # parte das faltas já é vista na reserva (RelQtty < Quantity)
PROB_DIVERGENCIA_CONFERENCIA = 0.04
PROB_RETIRA = 0.12                       # TipoFrete 9, sem transportadora
CONFIABILIDADE_TRANSP = (0.78, 0.98)     # prob. da transportadora coletar na janela prevista

# ============================================================
# Sujeira controlada da Bronze (justifica dedup/MERGE/hash na Silver)
# ============================================================
SUJEIRA_ATIVA = True
PROB_DUPLICATA_EXATA = 0.010
PROB_REEXTRACAO = 0.12            # versão antiga do mesmo documento (status anterior)
PROB_FORMATO_DATA_ALT = 0.03      # timestamps em dd/MM/yyyy HH:mm:ss
PROB_DECIMAL_VIRGULA = 0.05       # "12,50" em vez de 12.50
PROB_TEXTO_SUJO = 0.03            # caixa/espacos/UF por extenso
PROB_CARDCODE_NULO = 0.002        # pedido sem cliente (vai para membro desconhecido)
PROB_PRODUTO_REAJUSTE = 0.03      # nova versão do item com preço reajustado (dedup por UpdateDate)
