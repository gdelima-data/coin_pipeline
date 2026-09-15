# Crypto ClickHouse Pipeline

Pipeline de dados desenvolvido para coletar, armazenar, transformar, testar e visualizar dados de criptomoedas.

O projeto utiliza **Airflow** para orquestração, **ClickHouse** como banco analítico, **dbt** para transformação e testes, e **Power BI** para visualização dos dados. Toda a aplicação é executada em containers Docker hospedados em uma **VM do Azure**.

---

## Arquitetura

```text
                    ┌──────────────────┐
                    │    CoinGecko API │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │      Airflow     │
                    │   Orquestração   │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │    ClickHouse    │
                    │  Dados brutos    │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │       dbt        │
                    │ Transformações   │
                    │     + Testes     │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │      Power BI    │
                    │    Dashboard     │
                    └──────────────────┘
```

### Fluxo

1. O **Airflow** executa o pipeline de ingestão.
2. Os dados são coletados através da **CoinGecko API**.
3. Os dados são armazenados no **ClickHouse**.
4. O **dbt** transforma os dados em modelos analíticos.
5. O dbt executa testes de qualidade sobre os modelos.
6. O **Power BI** acessa o modelo final através de DirectQuery.
7. O dashboard apresenta indicadores de preço, retorno, volatilidade, market cap e volume.

---

## Tecnologias

| Tecnologia     | Função                           |
| -------------- | -------------------------------- |
| Python         | Ingestão e manipulação dos dados |
| Apache Airflow | Orquestração do pipeline         |
| ClickHouse     | Armazenamento analítico          |
| dbt            | Transformação e testes           |
| Docker         | Containerização                  |
| Docker Compose | Orquestração dos containers      |
| Azure VM       | Hospedagem                       |
| CoinGecko API  | Fonte dos dados                  |
| Power BI       | Visualização e análise           |

---

## Fonte dos dados

Os dados são obtidos através da **CoinGecko API**, utilizando o endpoint de mercados:

```text
/api/v3/coins/markets
```

A consulta considera:

* moeda de referência: USD
* ordenação: market cap
* quantidade: 10 criptomoedas
* página: 1

Exemplo dos parâmetros utilizados:

```text
vs_currency=usd
order=market_cap_desc
per_page=10
page=1
```

Entre os ativos coletados estão:

* Bitcoin (BTC)
* Ethereum (ETH)
* Tether (USDT)
* BNB
* XRP
* USD Coin (USDC)
* Solana (SOL)
* TRON (TRX)
* entre outros ativos retornados pela API.

---

# Estrutura do projeto

```text
crypto_clickhouse_pipeline/
│
├── dags/
│   └── crypto_pipeline.py
│
├── dbt_project/
│   ├── models/
│   │   ├── staging/
│   │   │   └── stg_crypto_metrics.sql
│   │   │
│   │   └── marts/
│   │       ├── fct_crypto_metrics.sql
│   │       └── schema.yml
│   │
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   └── package-lock.yml
│
├── Dockerfile
├── docker-compose.yml
├── ch_postgres_config.xml
├── requirements.txt
├── .env
├── .gitignore
└── README.md
```

Arquivos e diretórios gerados durante a execução, como logs, banco interno do Airflow e arquivos temporários do dbt, não fazem parte do versionamento.

---

# Banco de dados

O ClickHouse utiliza o banco:

```text
crypto_db
```

## Tabela de origem

```text
src_crypto_prices
```

Principais campos:

| Campo           | Tipo     | Descrição                    |
| --------------- | -------- | ---------------------------- |
| `id`            | String   | Identificador da criptomoeda |
| `symbol`        | String   | Símbolo do ativo             |
| `name`          | String   | Nome da criptomoeda          |
| `current_price` | Float64  | Preço atual                  |
| `market_cap`    | Float64  | Capitalização de mercado     |
| `total_volume`  | Float64  | Volume de negociação         |
| `extracted_at`  | DateTime | Momento da coleta            |

A tabela utiliza o mecanismo:

```text
MergeTree()
```

com ordenação por:

```text
extracted_at
```

---

# Transformações com dbt

O dbt organiza o processo de transformação em camadas.

## Staging

O modelo:

```text
stg_crypto_metrics
```

padroniza os dados provenientes da tabela de origem.

Entre os campos disponibilizados estão:

* `ticker`
* `coin_name`
* `price_usd`
* `market_cap`
* `total_volume`
* `extracted_at`

---

## Mart

O modelo:

```text
fct_crypto_metrics
```

produz uma visão analítica consolidada por criptomoeda.

Entre as métricas calculadas estão:

| Métrica                   | Descrição                         |
| ------------------------- | --------------------------------- |
| `avg_price_period`        | Preço médio no período            |
| `min_price_period`        | Menor preço observado             |
| `peak_price`              | Maior preço observado             |
| `first_price`             | Primeiro preço registrado         |
| `latest_price`            | Preço mais recente                |
| `price_change_pct`        | Variação percentual do preço      |
| `price_volatility_pct`    | Volatilidade percentual           |
| `avg_market_cap`          | Market cap médio                  |
| `latest_market_cap`       | Market cap mais recente           |
| `avg_volume`              | Volume médio                      |
| `latest_volume`           | Volume mais recente               |
| `volume_market_cap_ratio` | Relação entre volume e market cap |
| `observations`            | Quantidade de observações         |
| `first_update`            | Primeira coleta                   |
| `last_updated`            | Última coleta                     |

### Exemplo da variação de preço

A variação percentual é calculada comparando o primeiro preço registrado com o preço mais recente:

```text
((latest_price - first_price) / first_price) × 100
```

---

# Qualidade dos dados

O projeto utiliza testes do **dbt** para validar os dados.

São utilizados testes como:

* `not_null`
* `unique`
* validações de valores
* validações de métricas através do `dbt_utils`

A execução atual do projeto apresenta:

```text
PASS=31
WARN=0
ERROR=0
SKIP=0
NO-OP=0
TOTAL=31
```

Ou seja, os modelos e testes foram executados com sucesso.

---

# Airflow

O Airflow é responsável pela orquestração do pipeline.

O DAG principal é:

```text
crypto_clickhouse_pipeline
```

A execução contempla as etapas de ingestão e transformação dos dados.

A tarefa de transformação utiliza o dbt:

```text
dbt_run
```

O objetivo é manter no DAG a responsabilidade de **orquestrar** as etapas, enquanto as regras de transformação permanecem nos modelos dbt.

---

# Docker

Os componentes principais são executados através do Docker Compose.

Os serviços incluem:

```text
clickhouse
airflow
```

O ClickHouse disponibiliza:

```text
HTTP: 8123
Native: 9000
```

O Airflow disponibiliza sua interface web através da porta:

```text
8080
```

O projeto utiliza volumes Docker para persistir os dados do ClickHouse.

---

# Configuração

## Pré-requisitos

Para executar o projeto são necessários:

* Docker
* Docker Compose
* Git
* acesso à CoinGecko API

Para o ambiente de produção utilizado neste projeto:

* Azure VM
* Linux
* Docker Engine
* Docker Compose

---

## Variáveis de ambiente

Informações sensíveis são armazenadas em um arquivo `.env`.

Exemplo:

```env
CLICKHOUSE_PASSWORD=sua_senha
```

O arquivo `.env` **não deve ser versionado**.

O `.gitignore` contém:

```gitignore
.env
```

O dbt pode utilizar a variável de ambiente para acessar a senha do ClickHouse:

```yaml
password: "{{ env_var('CLICKHOUSE_PASSWORD') }}"
```

---

# Executando o projeto

Clone o repositório:

```bash
git clone git@github.com:gdelima-data/crypto_clickhouse_pipeline.git
cd crypto_clickhouse_pipeline
```

Crie o arquivo `.env`:

```bash
nano .env
```

Adicione:

```env
CLICKHOUSE_PASSWORD=sua_senha
```

Suba os containers:

```bash
docker compose up -d
```

Verifique os containers:

```bash
docker compose ps
```

---

# Executando o dbt

Como o hostname `clickhouse` pertence à rede Docker, os comandos do dbt que precisam acessar o banco devem ser executados dentro do container do Airflow.

Entre no container:

```bash
docker exec -it airflow-local bash
```

Entre no projeto:

```bash
cd /opt/airflow/dbt_project
```

Verifique a conexão:

```bash
dbt debug --target dev --profiles-dir .
```

Execute os modelos e testes:

```bash
dbt build --target dev --profiles-dir .
```

---

# Power BI

O modelo final:

```text
fct_crypto_metrics
```

é disponibilizado para análise através do **Power BI** utilizando **DirectQuery**.

O dashboard apresenta diferentes perspectivas do mercado de criptomoedas.

## Indicadores

Entre os principais indicadores estão:

* Market Cap total
* preço do Bitcoin
* melhor retorno
* volatilidade

## Visualizações

### Performance das criptomoedas

Comparação da variação percentual de preço entre os ativos.

### Market Cap

Distribuição da capitalização de mercado entre as criptomoedas.

### Participação no volume

Representação da participação de cada ativo no volume total de negociação.

### Risco × Retorno

Gráfico de dispersão:

```text
X → Volatilidade (%)
Y → Variação do Preço (%)
Tamanho → Market Cap Atual
```

Título utilizado:

> **Risco (Volatilidade) × Retorno das Criptomoedas**

Essa visualização permite comparar simultaneamente o retorno obtido e a volatilidade de cada ativo.

---

# Objetivo do projeto

Este projeto foi desenvolvido como um projeto de **Data Engineering**, com foco na construção de um pipeline completo de dados.

O objetivo não é realizar previsão de preços ou recomendar investimentos, mas demonstrar a implementação de um fluxo de dados envolvendo:

```text
API
 ↓
Ingestão
 ↓
Data Warehouse / OLAP
 ↓
Transformação
 ↓
Data Quality
 ↓
BI
```

O projeto também busca demonstrar conhecimentos em:

* ETL/ELT
* orquestração
* SQL
* modelagem analítica
* Data Quality
* Docker
* cloud
* Git
* BI

---

# Status

**Projeto V1 — concluído.**

Pipeline funcional de ponta a ponta:

```text
CoinGecko
    ↓
Airflow
    ↓
ClickHouse
    ↓
dbt
    ↓
Data Quality
    ↓
Power BI
```

O projeto está hospedado em uma VM Azure e utiliza Docker para execução dos principais componentes.
