import os
import pandas as pd
import numpy as np
from datetime import timedelta
import config
import utils

def gerar_fatos(df_clientes, df_produtos, df_filiais, df_operadores, df_transp, df_cal):
    print("Gerando Transações (Fatos - OPKL e OPKL1)...")
    
    clientes_list = df_clientes['CardCode'].tolist()
    produtos_list = df_produtos['ItemCode'].tolist()
    
    # Prepara array de filiais e seus pesos
    filiais_list = df_filiais['WhsCode'].tolist()
    pesos_filiais = []
    for f in filiais_list:
        estado = df_filiais[df_filiais['WhsCode'] == f]['State'].values[0]
        peso = config.PESO_DEMANDA_UF.get(estado, 1.0)
        pesos_filiais.append(peso)
    pesos_filiais = np.array(pesos_filiais) / np.sum(pesos_filiais)
    dict_filial_estado = dict(zip(df_filiais['WhsCode'], df_filiais['State']))
    operadores_list = df_operadores[df_operadores['Department'] == 'Operador']['USER_CODE'].tolist()
    transp_list = df_transp['TrnspCode'].tolist()
    
    datas_2026 = pd.date_range(config.DATA_INICIO, config.DATA_FIM_ANO)
    
    opkl_records = []
    opkl1_records = []
    
    abs_entry_seq = 1
    doc_entry_seq = 1 # Order ID
    
    for current_date in datas_2026:
        if current_date > config.DATA_CORTE:
            break
            
        fator_sazonal = 1.0
        if current_date.weekday() >= 5: 
            fator_sazonal = 0.3
        elif current_date.weekday() == 0: 
            fator_sazonal = 1.4
            
        if current_date.month == 11 and current_date.day > 20:
            fator_sazonal *= 2.5
            
        qtd_pedidos_hoje = int((config.PEDIDOS_POR_MES / 30) * fator_sazonal)
        
        for _ in range(qtd_pedidos_hoje):
            cliente = np.random.choice(clientes_list)
            filial = np.random.choice(filiais_list, p=pesos_filiais)
            transportadora = np.random.choice(transp_list)
            
            hora_pedido = current_date + timedelta(hours=np.random.randint(8, 16), minutes=np.random.randint(0, 60))
            if hora_pedido > config.DATA_CORTE:
                continue
                
            cod_pedido = f"PD{str(doc_entry_seq).zfill(8)}"
            
            # Status e Máquina de Estados
            rand_status = np.random.random()
            if rand_status < config.PROB_CANCELAMENTO_ANTES_PICKING:
                status_final = 'C' 
                cancelado = 'Y'
            elif rand_status < (config.PROB_CANCELAMENTO_ANTES_PICKING + 0.10): # pendente
                status_final = 'P' 
                cancelado = 'N'
            else:
                status_final = 'E' 
                cancelado = 'N'
                
            qtd_sku = np.random.randint(1, 6)
            nf = f"NF{str(doc_entry_seq).zfill(6)}"
            
            ts_inicio_sep = ts_fim_sep = ts_conferencia = ts_fim_conf = ts_saida = None
            operador_sep = conferente = expedidor = None
            pronto_impressao = None
            pronto_conferencia = None
            
            if status_final != 'P' and status_final != 'C':
                minutos_atraso = np.random.randint(2, 15) if filial != 'F25' else np.random.randint(1, 5)
                pronto_impressao = hora_pedido + timedelta(minutes=2)
                ts_inicio_sep = pronto_impressao + timedelta(minutes=minutos_atraso)
                estado_filial = dict_filial_estado[filial]
                if estado_filial == 'SP':
                    if np.random.random() < 0.90:
                        minutos_sep = np.random.randint(12, 18) # SLA: 13 a 18
                    else:
                        minutos_sep = np.random.randint(18, 22) # SLA: 19 a 22
                elif estado_filial in ['RJ', 'MG', 'ES']:
                    if np.random.random() < 0.80:
                        minutos_sep = np.random.randint(13, 18) # SLA: 14 a 18
                    else:
                        minutos_sep = np.random.randint(18, 24) # SLA: 19 a 24
                elif estado_filial in ['PR', 'RS', 'SC']:
                    if np.random.random() < 0.70:
                        minutos_sep = np.random.randint(14, 18) # SLA: 15 a 18
                    else:
                        minutos_sep = np.random.randint(18, 25) # SLA: 19 a 25
                else:
                    if np.random.random() < 0.50:
                        minutos_sep = np.random.randint(15, 18) # SLA: 16 a 18
                    else:
                        minutos_sep = np.random.randint(18, 28) # SLA: 19 a 28
                ts_fim_sep = ts_inicio_sep + timedelta(minutes=minutos_sep)
                pronto_conferencia = ts_fim_sep + timedelta(minutes=1)
                ts_conferencia = pronto_conferencia + timedelta(minutes=np.random.randint(1, 5))
                ts_fim_conf = ts_conferencia + timedelta(minutes=np.random.randint(2, 8))
                ts_saida = ts_fim_conf + timedelta(hours=np.random.randint(1, 4))
                operador_sep = np.random.choice(operadores_list)
                conferente = np.random.choice(operadores_list)
                expedidor = np.random.choice(operadores_list)
                
            # Adiciona Cabecalho OPKL
            opkl_records.append({
                'AbsEntry': abs_entry_seq,
                'PickDate': hora_pedido.strftime('%Y-%m-%d'),
                'Status': status_final,
                'U_CodPedido': cod_pedido,
                'U_DataPedido': hora_pedido.strftime('%Y-%m-%d %H:%M:%S'),
                'U_CodCliente': cliente,
                'U_Filial': filial,
                'U_IdSeparador': operador_sep,
                'U_ProntoParaImpressao': pronto_impressao.strftime('%Y-%m-%d %H:%M:%S') if pronto_impressao else None,
                'U_EmSeparacao': ts_inicio_sep.strftime('%Y-%m-%d %H:%M:%S') if ts_inicio_sep else None,
                'U_ProntoParaConferencia': pronto_conferencia.strftime('%Y-%m-%d %H:%M:%S') if pronto_conferencia else None,
                'U_EmConferencia': ts_conferencia.strftime('%Y-%m-%d %H:%M:%S') if ts_conferencia else None,
                'U_Conferido': ts_fim_conf.strftime('%Y-%m-%d %H:%M:%S') if ts_fim_conf else None,
                'U_Saida': ts_saida.strftime('%Y-%m-%d %H:%M:%S') if ts_saida else None,
                'U_CodTransp': transportadora,
                'CreateDate': hora_pedido.strftime('%Y-%m-%d'),
                'UpdateDate': (ts_saida if ts_saida else hora_pedido).strftime('%Y-%m-%d %H:%M:%S')
            })
            
            # Adiciona Itens OPKL1
            for pick_entry in range(1, qtd_sku + 1):
                sku = np.random.choice(produtos_list)
                rel_qtty = np.random.randint(1, 10)
                pick_qtty = rel_qtty if status_final == 'E' else 0
                
                opkl1_records.append({
                    'AbsEntry': abs_entry_seq,
                    'PickEntry': pick_entry,
                    'OrderEntry': doc_entry_seq,
                    'OrderLine': pick_entry,
                    'ItemCode': sku,
                    'RelQtty': rel_qtty,
                    'PickQtty': pick_qtty
                })
                
            abs_entry_seq += 1
            doc_entry_seq += 1

    df_opkl = pd.DataFrame(opkl_records)
    df_opkl1 = pd.DataFrame(opkl1_records)
    
    utils.salvar(df_opkl, 'OPKL')
    utils.salvar(df_opkl1, 'OPKL1')
    return df_opkl, df_opkl1

if __name__ == '__main__':
    print("Execute pelo main.py para carregar as dimensões primeiro.")
