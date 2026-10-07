import os
import sys
import subprocess

# Garante que o Faker esteja instalado
try:
    import faker
except ImportError:
    print("Instalando a biblioteca 'faker'...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "faker"])

from gerar_dimensoes import gerar_todas_dimensoes
from gerar_fatos import gerar_fatos
from gerar_desconsideracoes import gerar_desconsideracoes
import config

def main():
    print("--- Iniciando Gerador de Dados Sintéticos ---")
    
    if config.MODE == 'DATABRICKS':
        print("\n--- Executando Setup do Catálogo (Databricks) ---")
        try:
            from pyspark.sql import SparkSession
            spark = SparkSession.builder.getOrCreate()
            
            try:
                base_path = os.path.dirname(os.path.abspath(__file__))
            except NameError:
                base_path = os.getcwd()
                
            setup_path = os.path.join(base_path, 'setup_catalog.sql')
            with open(setup_path, 'r', encoding='utf-8') as f:
                setup_sql = f.read()

            commands = [
                cmd.strip() for cmd in setup_sql.split(';') 
                if cmd.strip() and not all(l.strip().startswith('--') for l in cmd.strip().split('\n') if l.strip())
            ]
            for cmd in commands:
                spark.sql(cmd)
            print("Setup do catálogo e volume concluído com sucesso!")
        except Exception as e:
            print(f"Erro ao executar setup via Spark: {e}")

    # 1. Garante que as pastas existem
    os.makedirs(config.BASES_DIR, exist_ok=True)
    
    # 2. Gera os dados mestres (Dimensões)
    print("\n--- Etapa 1: Gerando Dados Mestres ---")
    df_clientes, df_produtos, df_filiais, df_operadores, df_transp = gerar_todas_dimensoes()
    
    # 3. Gera as transações (Fatos)
    print("\n--- Etapa 2: Gerando Transações ---")
    gerar_fatos(df_clientes, df_produtos, df_filiais, df_operadores, df_transp, None)
    
    # 4. Gera a tabela auxiliar de Desconsiderações
    print("\n--- Etapa 3: Gerando Desconsiderações (AUX) ---")
    gerar_desconsideracoes()
    
    print("\n--- Geração concluída com sucesso! ---")
    print(f"Arquivos disponíveis na pasta: {config.BASES_DIR}")
    if config.MODE == 'LOCAL':
        print("Para rodar no Databricks, lembre-se de executar o script de Setup antes de fazer o upload:")
        print("-> gerar_dados_fake/scripts/setup_catalog.sql")
    else:
        print("\nOs dados já foram enviados para o Volume do Unity Catalog.")
        print("Basta executar a DAG/Workflow para processar as camadas Bronze, Silver e Gold!")

if __name__ == '__main__':
    main()
