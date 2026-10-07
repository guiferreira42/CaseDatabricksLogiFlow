import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import config
import utils

NOMES = ['joao', 'maria', 'carlos', 'ana', 'pedro', 'lucas', 'julia', 'fernanda', 'marcos', 'paula']
SOBRENOMES = ['silva', 'santos', 'oliveira', 'souza', 'costa', 'pereira', 'rodrigues', 'almeida']

def gerar_desconsideracoes(qtd=10000):
    print(f"Gerando {qtd} Desconsiderações (AUX_Desconsideracoes)...")
    
    filiais_str = []
    for i, estado in enumerate(config.ESTADOS):
        filiais_str.append(f"F{str(i+1).zfill(2)} - Flow {estado}")
        
    motivos = [
        "Problema sistêmico - Lentidão ou travamento",
        "TI acessando computador da filial - Manutenção",
        "Filial Fechada p/ Almoço - Operando com 1 Op.",
        "Reunião",
        "Erro de pedido - Com necessidade de edição",
        "Atendimento a prestador de serviço",
        "Atendimento ao cliente - Troca/Devolução/Garantia",
        "Atendimento à transportadora",
        "Falta de energia",
        "Falta de internet",
        "Problema com impressora",
        "Atestado médico",
        "Ausente da filial - Emergência",
        "WC",
        "Feriado na UF da Filial"
    ]
    
    registros = []
    
    for _ in range(qtd):
        filial = random.choice(filiais_str)
        
        if random.random() < 0.05:
            cod_pick_list = "0"
        else:
            cod_pick_list = str(random.randint(100000, 999999))
            
        # Data de parada (dentro de 2026)
        dias_offset = random.randint(0, 360)
        data_parada = config.DATA_INICIO + timedelta(days=dias_offset)
        
        hora_parada = random.randint(6, 18)
        minuto_parada = random.randint(0, 59)
        
        # Duração da parada (5 a 120 minutos)
        duracao = random.randint(5, 120)
        
        dt_parada = datetime(data_parada.year, data_parada.month, data_parada.day, hora_parada, minuto_parada)
        dt_retorno = dt_parada + timedelta(minutes=duracao)
        
        registros.append({
            "Filial": filial,
            "CodPickList": cod_pick_list,
            "DataParada": dt_parada.strftime("%Y-%m-%d"),
            "HoraParada": dt_parada.hour,
            "MinutoParada": dt_parada.minute,
            "DataRetorno": dt_retorno.strftime("%Y-%m-%d"),
            "HoraRetorno": dt_retorno.hour,
            "MinutoRetorno": dt_retorno.minute,
            "Motivo": random.choice(motivos),
            "Email": f"{random.choice(NOMES)}.{random.choice(SOBRENOMES)}@logiflow.com.br"
        })
        
    df = pd.DataFrame(registros)
    
    utils.salvar(df, 'AUX_Desconsideracoes')
    return df

if __name__ == "__main__":
    gerar_desconsideracoes()
