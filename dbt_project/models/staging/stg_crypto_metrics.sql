{{ config(materialized='view') }}

SELECT
    upper(symbol) AS ticker,
    name as coin_name,
    current_price AS price_usd,
    market_cap,
    total_volume,
    extracted_at
FROM crypto_db.src_crypto_prices