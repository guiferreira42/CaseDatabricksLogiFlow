import os
import zlib
from datetime import date, datetime, timedelta
import config

# ============================================================
# Escrita: bases/<TABELA>/<TABELA>_<yyyymmdd_HHMMSS>.csv ou Volume Databricks
# ============================================================
CARIMBO_EXTRACAO = config.DATA_CORTE.strftime('%Y%m%d_%H%M%S')


def salvar(df, tabela):
    nome_arquivo = f'{tabela}_{CARIMBO_EXTRACAO}.csv'
    
    if config.MODE == 'DATABRICKS':
        # Salva em arquivo temporário e envia via Databricks SDK
        import tempfile
        from databricks.sdk import WorkspaceClient
        
        # Inicializa o client do SDK
        w = WorkspaceClient()
        
        # Caminho do Volume no Unity Catalog
        volume_path = f"/Volumes/{config.DATABRICKS_CATALOG}/{config.DATABRICKS_SCHEMA_BRONZE}/{config.DATABRICKS_VOLUME_BRONZE}/{tabela}"
        
        try:
            w.files.create_directory(volume_path)
        except Exception as e:
            pass
            
        caminho_completo = f"{volume_path}/{nome_arquivo}"
        
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_file = os.path.join(temp_dir, nome_arquivo)
            df.to_csv(temp_file, index=False, sep=';', encoding='utf-8')
            
            with open(temp_file, "rb") as f:
                w.files.upload(caminho_completo, f, overwrite=True)
                
        print(f'  -> {tabela:<14} {len(df):>9,} linhas  ({caminho_completo})')
        return caminho_completo
        
    else:
        # Modo LOCAL
        pasta = os.path.join(config.BASES_DIR, tabela)
        os.makedirs(pasta, exist_ok=True)
        caminho = os.path.join(pasta, nome_arquivo)
        df.to_csv(caminho, index=False, sep=';', encoding='utf-8')
        print(f'  -> {tabela:<14} {len(df):>9,} linhas  ({os.path.relpath(caminho, config.BASE_DIR)})')
        return caminho
