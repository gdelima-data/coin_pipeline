# Crypto Analytical Pipeline: Airflow, dbt & ClickHouse 🚀

Este projeto implementa uma estrutura de engenharia de dados para captura, armazenamento, transformação e disponibilização de dados analíticos sobre o mercado de criptomoedas. 

O pipeline consome dados reais da API pública da CoinGecko, gerencia o fluxo de tarefas usando o Apache Airflow, armazena os dados brutos e transformados no banco colunar ClickHouse e executa a modelagem nas camadas *Silver* e *Gold* através do dbt.

---

## 🏗️ Arquitetura do Projeto

O pipeline segue o conceito de arquitetura **ELT** (Extract, Load, Transform) dividido em camadas (Medallion Architecture):  
[ API CoinGecko ]  
│  
▼  
(Extract & Load via PythonOperator)  
[ Airflow: ingest_task ] ───> [ ClickHouse: crypto_db.src_crypto_prices ] (Camada Bronze/Raw)  
│  
▼  
(Orchestrate via BashOperator)  
[ Airflow: dbt_run ]  
│  
├─> [ dbt: stg_crypto_prices ] ──> View no ClickHouse (Camada Silver/Staging)  
└─> [ dbt: fct_crypto_metrics ] ─> Tabela no ClickHouse (Camada Gold/Marts)  

1. **Camada Bronze (Raw):** Dados brutos ingeridos diretamente da API REST em formato tabular.
2. **Camada Silver (Staging):** Limpeza, padronização de tickers em caixa alta e renomeação de campos estruturados como uma `VIEW` interativa.
3. **Camada Gold (Marts):** Agrupamento analítico contendo médias de período com arredondamento fixo de 2 casas decimais e picos de preço históricos estruturados como uma `TABLE` de alta performance.

---

## 🛠️ Tecnologias Utilizadas

* **Orquestração:** Apache Airflow 2.7.1 (Rodando em modo Standalone customizado)
* **Transformação de Dados:** dbt-core 1.11.11 & dbt-clickhouse
* **Banco de Dados Analítico:** ClickHouse Server (Engine MergeTree)
* **Ambiente de Isolamento:** Docker & Docker Compose
* **Linguagem Base:** Python 3.10 (Bibliotecas: `requests`, `clickhouse-driver`)

---

## ⚡ Desafios de Infraestrutura Superados (Lições Aprendidas)

Durante o desenvolvimento no ambiente local utilizando **Windows 11 com WSL2**, identificou-se um gargalo crítico de concorrência ao mapear o volume de dados do ClickHouse para diretórios locais sincronizados automaticamente por ferramentas de nuvem (como o **OneDrive**). 

O motor de tabelas `MergeTree` do ClickHouse executa operações de escrita e renomeações atômicas de arquivos em disco muito rápidas (`moveDirectory` / `renameTo`). A trava temporária de arquivos imposta pelo sincronizador do Windows gerava exceções fatais de C++ (`std::filesystem::filesystem_error`). 

**Solução Aplicada:** A infraestrutura do `docker-compose.yml` foi refatorada para utilizar um **volume nomeado nativo gerenciado pelo Linux dentro do WSL2** (`clickhouse_pure_volume`). Isso eliminou a camada de tradução de permissões do Windows e garantiu a estabilidade e a performance colunar do banco de dados.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
* Docker Desktop instalado e configurado com WSL2.
* Git para clonar o repositório.

### Passo a Passo

1. **Clonar o repositório:**
   git clone <link-do-seu-repositorio>
   cd <nome-da-pasta-do-projeto>

2. **Inicializar a Stack (Docker):**
Execute o comando abaixo para construir a imagem customizada do Airflow (contendo os drivers do dbt e do ClickHouse) e subir os serviços de forma isolada:
   docker compose up -d --build

3. **Executar o Pipeline no Airflow:**
Acesse o painel de controle do Airflow em: http://localhost:8080

Ative a DAG crypto_clickhouse_pipeline mudando a chave para Unpause.

Clique em Trigger DAG (botão de Play) para rodar o pipeline manualmente.

4. **Visualizar os Resultados no ClickHouse:**
Acesse o cliente web do ClickHouse em http://localhost:8123/play, faça login com usuário admin e senha admin, e execute as queries de validação:  
-- Validar tabelas criadas pelo dbt
   SHOW TABLES FROM crypto_db;  

-- Consultar os dados finais refinados (Camada Gold)  
   SELECT * FROM crypto_db.fct_crypto_metrics;  

5. **Encerrar e Liberar Memória RAM:**
Ao finalizar os testes, você pode derrubar os containers e desligar a instância do WSL2 para liberar totalmente a memória do seu computador host:
docker compose down
   wsl --shutdown
