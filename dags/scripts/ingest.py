import requests
import os
from clickhouse_driver import Client

def fetch_and_load_api():
    url = 'https://api.coingecko.com/api/v3/coins/markets'

    params = {
      'vs_currency': 'usd',
      'order': 'market_cap_desc',
      'per_page': 250,
      'page': 1
    }

    all_data = []

    while True:
	response = requests.get(
	base_url,
	params=params,
	timeout=30
	)

        data = response.json()

        if not data:
	     break

         all_data.extend(data)

         print(f'Página {params['page']} coletada: '
         f'{len(data)} registros'
         )

         params['page'] += 1
     
    print(f'Total coletado: {len(all_data)} registros')


    client = Client(host='clickhouse', user='admin', password=os.environ['CLICKHOUSE_PASSWORD'], database='crypto_db')

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
