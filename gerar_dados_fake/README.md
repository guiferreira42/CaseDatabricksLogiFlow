# Gerador de Dados Sintéticos - LogiFlow (Papelaria)

Este diretório contém os scripts em Python responsáveis por gerar toda a massa de dados transacionais e dimensionais para o case LogiFlow Analytics. 

A ferramenta atua como o sistema transacional do projeto, simulando o banco de dados de um ERP **SAP Business One (HANA DB)** em uma operação nacional focada na distribuição de papelaria e suprimentos corporativos (cadernos, canetas, resmas, móveis de escritório, etc.). Os dados gerados respeitam rigorosamente cardinalidades e volumetrias do mundo real.

## 📁 Estrutura do Módulo

- `scripts/`: Códigos Python modulares para geração dos dados (`main.py`, `gerar_fatos.py`, `gerar_dimensoes.py`). Também hospeda o script `setup_catalog.sql`.
- `bases/`: Diretório de escape local. Utilizado apenas caso você opte por gerar os arquivos `.csv` diretamente na sua máquina (modo offline).

## 🗃️ Entidades Simuladas (Padrão SAP B1)

1. **Dados Mestres (Dimensões):**
   - `OCRD.csv` (Clientes): Cadastro corporativo e pessoas físicas da papelaria.
   - `OITM.csv` (Produtos): Mix de itens agrupados por famílias (Acessórios, Papelaria, Organização, Móveis, etc).
   - `OWHS.csv` (Filiais): 27 armazéns de distribuição (1 por estado brasileiro), nomeados no formato "Flow [UF]".
   - `OUSR.csv` (Usuários): Operadores de chão de fábrica e supervisores, distribuídos pelas grandes regiões do país.
   - `OSHP.csv` (Transportadoras): Lista de modais logísticos parceiros.
   - `AUX_Desconsideracoes.csv`: Tabela de controle de negócio, que aponta picklists que a equipe gerencial invalidou (por duplicidade ERP, testes sistêmicos, etc).

2. **Transações Logísticas (Fato):**
   - `OPKL.csv` (Cabeçalho de Picklists) e `OPKL1.csv` (Linhas/Itens de Picklists): Guarda o rastreio (Time Tracking) cronológico da operação. Simula o tempo desde a *Criação do Pedido* até as etapas de *Separação, Conferência e Saída do Armazém*.

## 🚀 Como Executar

O gerador suporta rodar direto no cluster Databricks (ideal para orquestração automática) ou localmente na sua máquina.

1. (Opcional se local) Instale as dependências:
   ```bash
   pip install pandas numpy faker databricks-sdk
   ```

2. Defina a sua estratégia no arquivo `scripts/config.py`:
   - `MODE = 'LOCAL'`: Salva os CSVs localmente na pasta `bases/`. Você terá que subir manualmente para o Databricks.
   - `MODE = 'DATABRICKS'`: Aciona o Spark para criar automaticamente o catálogo/schemas (`setup_catalog.sql`) e, logo em seguida, usa o Databricks SDK para depositar todos os CSVs recém-nascidos diretamente no Volume `logiflow.bronze.raw_data`.

3. Acione o motor:
   ```bash
   python scripts/main.py
   ```
