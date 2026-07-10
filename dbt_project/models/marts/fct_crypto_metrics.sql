{{ config(materialized='table') }}

SELECT
    ticker,
    coin_name,
    avg(price_usd) AS avg_price_period,
    max(price_usd) AS peak_price,
    max(extracted_at) AS last_updated
FROM {{ ref('stg_crypto_metrics') }}
GROUP BY ticker, coin_name