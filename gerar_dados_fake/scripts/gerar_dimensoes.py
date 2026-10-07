import os
import pandas as pd
import numpy as np
from faker import Faker
import config

fake = Faker('pt_BR')

def gerar_clientes():
    print("Gerando Clientes (OCRD)...")
    clientes = []
    for i in range(1, config.QTD_CLIENTES + 1):
        clientes.append({
            'CardCode': f"C{str(i).zfill(6)}",
            'CardName': fake.company(),
            'LicTradNum': fake.cnpj(),
            'E_Mail': fake.company_email(),
            'State1': fake.random_element(elements=config.ESTADOS),
            'City': fake.city(),
            'ZipCode': fake.postcode(),
            'Address': fake.street_address(),
            'Phone1': fake.phone_number(),
            'CreateDate': fake.date_between(start_date='-5y', end_date='today').strftime('%Y-%m-%d %H:%M:%S'),
            'UpdateDate': fake.date_between(start_date='today', end_date='today').strftime('%Y-%m-%d %H:%M:%S'),
            'validFor': 'Y' if np.random.random() > 0.05 else 'N'
        })
    df = pd.DataFrame(clientes)
    import utils
    utils.salvar(df, 'OCRD')
    return df

def gerar_produtos():
    print("Gerando Produtos (OITM)...")
    produtos = []
    
    grupos_ids = list(config.GRUPOS_PRODUTO.keys())
    
    for i in range(1, config.QTD_PRODUTOS + 1):
        grupo_id = np.random.choice(grupos_ids)
        nome_grupo = config.GRUPOS_PRODUTO[grupo_id][0]
        
        produtos.append({
            'ItemCode': f"P{str(i).zfill(5)}",
            'ItemName': f"{nome_grupo} {fake.word().capitalize()} {fake.color_name()}",
            'ItmsGrpCod': grupo_id,
            'SalUnitMsr': np.random.choice(['UN', 'CX', 'PCT']),
            'BuyUnitMsr': np.random.choice(['CX', 'PALETE']),
            'SWeight1': round(np.random.uniform(0.1, 5.0), 3),
            'SLength1': round(np.random.uniform(5.0, 50.0), 2),
            'SWidth1': round(np.random.uniform(5.0, 50.0), 2),
            'SHeight1': round(np.random.uniform(5.0, 50.0), 2),
            'CodeBars': fake.ean13(),
            'validFor': 'Y' if np.random.random() > 0.05 else 'N',
            'CreateDate': fake.date_between(start_date='-5y', end_date='today').strftime('%Y-%m-%d')
        })
    df = pd.DataFrame(produtos)
    
    import utils
    utils.salvar(df, 'OITM')
    return df

def gerar_filiais():
    print("Gerando Filiais (OWHS)...")
    filiais = []
    for i, estado in enumerate(config.ESTADOS):
        filiais.append({
            'WhsCode': f"F{str(i+1).zfill(2)}",
            'WhsName': f"Flow {estado}",
            'State': estado,
            'City': fake.city(),
            'ZipCode': fake.postcode(),
            'Street': fake.street_name()
        })
    df = pd.DataFrame(filiais)
    import utils
    utils.salvar(df, 'OWHS')
    return df

def gerar_operadores():
    print("Gerando Operadores e Supervisores (OUSR)...")
    operadores = []
    
    # Supervisores
    supervisor_ids = []
    for regiao in config.REGIOES:
        for _ in range(config.SUPERVISORES_POR_REGIAO):
            sup_id = f"S{str(len(supervisor_ids)+1).zfill(3)}"
            supervisor_ids.append(sup_id)
            operadores.append({
                'USER_CODE': sup_id,
                'U_NAME': fake.name(),
                'Department': 'Supervisor',
                'Branch': regiao
            })
            
    # Operadores
    for i in range(1, config.QTD_OPERADORES + 1):
        operadores.append({
            'USER_CODE': f"O{str(i).zfill(4)}",
            'U_NAME': fake.name(),
            'Department': 'Operador',
            'Branch': fake.random_element(elements=list(config.REGIOES.keys()))
        })
        
    df = pd.DataFrame(operadores)
    import utils
    utils.salvar(df, 'OUSR')
    return df

def gerar_transportadoras():
    print("Gerando Transportadoras (OSHP)...")
    transportadoras = []
    for i in range(1, config.QTD_TRANSPORTADORAS + 1):
        transportadoras.append({
            'TrnspCode': f"T{str(i).zfill(3)}",
            'TrnspName': f"Logística {fake.company()}",
            'WebSite': fake.url()
        })
    df = pd.DataFrame(transportadoras)
    import utils
    utils.salvar(df, 'OSHP')
    return df

def gerar_todas_dimensoes():
    clientes = gerar_clientes()
    produtos = gerar_produtos()
    filiais = gerar_filiais()
    operadores = gerar_operadores()
    transp = gerar_transportadoras()
    return clientes, produtos, filiais, operadores, transp

if __name__ == '__main__':
    gerar_todas_dimensoes()
