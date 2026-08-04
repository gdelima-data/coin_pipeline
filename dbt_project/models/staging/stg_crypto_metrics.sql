{{ config(materialized='incremental',
          engine='MergeTree()',
          order_by='extracted_at') }}

SELECT
    upper(symbol) AS ticker,
    name as coin_name,
    current_price AS price_usd,
    market_cap,
    total_volume,
    extracted_at
FROM {{ source('crypto_db', 'src_crypto_prices')}}

{% if is_incremental()%}
   WHERE extracted_at > (SELECT max(extracted_at) FROM {{ this }})
{% endif %}