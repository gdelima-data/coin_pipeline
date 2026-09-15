{{ config(materialized='table') }}

WITH aggregated AS (

    SELECT
        ticker,
        coin_name,

        -- Preços
        avg(price_usd) AS avg_price_period,
        min(price_usd) AS min_price_period,
        max(price_usd) AS peak_price,

        -- Primeira e última observação
        argMin(price_usd, extracted_at) AS first_price,
        argMax(price_usd, extracted_at) AS latest_price,

        min(extracted_at) AS first_update,
        max(extracted_at) AS last_updated,

        -- Dados de mercado
        avg(market_cap) AS avg_market_cap,
        argMax(market_cap, extracted_at) AS latest_market_cap,

        avg(total_volume) AS avg_volume,
        argMax(total_volume, extracted_at) AS latest_volume,

        -- Quantidade de observações
        count(*) AS observations

    FROM {{ ref('stg_crypto_metrics') }}

    GROUP BY
        ticker,
        coin_name
)

SELECT
    ticker,
    coin_name,

    -- Preços
    round(avg_price_period, 2) AS avg_price_period,
    round(min_price_period, 2) AS min_price_period,
    round(peak_price, 2) AS peak_price,
    round(first_price, 2) AS first_price,
    round(latest_price, 2) AS latest_price,

    -- Variação do preço no período
    round(
        ((latest_price - first_price) / nullIf(first_price, 0)) * 100,
        2
    ) AS price_change_pct,

    -- Volatilidade: amplitude entre máximo e mínimo
    round(
        ((peak_price - min_price_period) / nullIf(min_price_period, 0)) * 100,
        2
    ) AS price_volatility_pct,

    -- Market Cap
    round(avg_market_cap, 2) AS avg_market_cap,
    round(latest_market_cap, 2) AS latest_market_cap,

    -- Volume
    round(avg_volume, 2) AS avg_volume,
    round(latest_volume, 2) AS latest_volume,

    -- Relação volume / market cap
    round(
        latest_volume / nullIf(latest_market_cap, 0),
        4
    ) AS volume_market_cap_ratio,

    -- Metadados
    observations,
    first_update,
    last_updated

FROM aggregated
