import requests
from clickhouse_driver import Client

def fetch_and_load_api():
    url = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1'
    response = requests.get(url).json()

    client = Client(host='clickhouse', user='admin', password='admin', database='crypto_db')

    client.execute(
        """
        CREATE TABLE IF NOT EXISTS src_crypto_prices (
            id String,
            symbol String,
            name String,
            current_price Float64,
            market_cap Float64,
            total_volume Float64,
            extracted_at DateTime DEFAULT now()
        ) ENGINE = MergeTree() ORDER BY extracted_at
        """
    )

    data_to_insert = [
        (coin['id'], coin['symbol'], coin['name'], coin['current_price'], coin['market_cap'], coin['total_volume'])
        for coin in response
    ]

    client.execute(
        "INSERT INTO src_crypto_prices (id, symbol, name, current_price, market_cap, total_volume) VALUES", 
        data_to_insert
    )