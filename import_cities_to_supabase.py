#!/usr/bin/env python3
"""
Import Cities Database to Supabase
This script downloads the cities data from the GitHub repository and imports it to Supabase.
"""

import json
import requests
import psycopg2
from psycopg2.extras import execute_batch
import sys

# Supabase connection details
# Using pooler connection for better connectivity
DB_HOST = "aws-0-us-east-1.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.jaazuuohrdnaggovntit"
DB_PASSWORD = None  # Will be provided as command line argument

# GitHub raw content URLs
COUNTRIES_URL = "https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/countries.json"
STATES_URL = "https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/states.json"
CITIES_URL = "https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/json/cities.json"


def download_json_data(url):
    """Download JSON data from URL"""
    print(f"Downloading data from {url}...")
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404:
            # Try alternative path
            alt_url = url.replace("/json/", "/cities/")
            print(f"Trying alternative URL: {alt_url}")
            response = requests.get(alt_url, timeout=60)
            response.raise_for_status()
            return response.json()
        raise
    except Exception as e:
        print(f"Error downloading data: {e}")
        raise


def create_tables(conn):
    """Create the necessary tables in Supabase"""
    cursor = conn.cursor()

    # Create countries table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS countries (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            iso3 VARCHAR(3),
            iso2 VARCHAR(2),
            numeric_code VARCHAR(3),
            phone_code VARCHAR(255),
            capital VARCHAR(255),
            currency VARCHAR(255),
            currency_name VARCHAR(255),
            currency_symbol VARCHAR(255),
            tld VARCHAR(255),
            native VARCHAR(255),
            region VARCHAR(255),
            subregion VARCHAR(255),
            latitude DECIMAL(10, 8),
            longitude DECIMAL(11, 8),
            emoji VARCHAR(191),
            emoji_u VARCHAR(191),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(iso2)
        );
    """)

    # Create states table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS states (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            country_id INTEGER REFERENCES countries(id),
            country_code VARCHAR(2),
            fips_code VARCHAR(255),
            iso2 VARCHAR(255),
            state_code VARCHAR(255),
            latitude DECIMAL(10, 8),
            longitude DECIMAL(11, 8),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    """)

    # Create cities table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS cities (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            state_id INTEGER REFERENCES states(id),
            state_code VARCHAR(255),
            country_id INTEGER REFERENCES countries(id),
            country_code VARCHAR(2),
            latitude DECIMAL(10, 8),
            longitude DECIMAL(11, 8),
            wiki_data_id VARCHAR(255),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    """)

    # Create indexes for better performance
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_cities_country_id ON cities(country_id);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_cities_state_id ON cities(state_id);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_cities_name ON cities(name);")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_states_country_id ON states(country_id);")

    conn.commit()
    print("Tables created successfully!")


def import_countries(conn, countries_data):
    """Import countries data"""
    cursor = conn.cursor()

    print(f"Importing {len(countries_data)} countries...")

    insert_query = """
        INSERT INTO countries (
            id, name, iso3, iso2, numeric_code, phone_code, capital, currency,
            currency_name, currency_symbol, tld, native, region, subregion,
            latitude, longitude, emoji, emoji_u
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) ON CONFLICT (iso2) DO UPDATE SET
            name = EXCLUDED.name,
            iso3 = EXCLUDED.iso3,
            updated_at = NOW();
    """

    data_to_insert = []
    for country in countries_data:
        data_to_insert.append((
            country.get('id'),
            country.get('name'),
            country.get('iso3'),
            country.get('iso2'),
            country.get('numeric_code'),
            country.get('phone_code'),
            country.get('capital'),
            country.get('currency'),
            country.get('currency_name'),
            country.get('currency_symbol'),
            country.get('tld'),
            country.get('native'),
            country.get('region'),
            country.get('subregion'),
            country.get('latitude'),
            country.get('longitude'),
            country.get('emoji'),
            country.get('emojiU')
        ))

    execute_batch(cursor, insert_query, data_to_insert, page_size=1000)
    conn.commit()
    print(f"Imported {len(countries_data)} countries successfully!")


def import_states(conn, states_data):
    """Import states data"""
    cursor = conn.cursor()

    print(f"Importing {len(states_data)} states...")

    insert_query = """
        INSERT INTO states (
            id, name, country_id, country_code, fips_code, iso2,
            state_code, latitude, longitude
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            updated_at = NOW();
    """

    data_to_insert = []
    for state in states_data:
        data_to_insert.append((
            state.get('id'),
            state.get('name'),
            state.get('country_id'),
            state.get('country_code'),
            state.get('fips_code'),
            state.get('iso2'),
            state.get('state_code'),
            state.get('latitude'),
            state.get('longitude')
        ))

    execute_batch(cursor, insert_query, data_to_insert, page_size=1000)
    conn.commit()
    print(f"Imported {len(states_data)} states successfully!")


def import_cities(conn, cities_data):
    """Import cities data in batches"""
    cursor = conn.cursor()

    print(f"Importing {len(cities_data)} cities (this may take a while)...")

    insert_query = """
        INSERT INTO cities (
            id, name, state_id, state_code, country_id, country_code,
            latitude, longitude, wiki_data_id
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            updated_at = NOW();
    """

    # Process in batches
    batch_size = 5000
    total = len(cities_data)

    for i in range(0, total, batch_size):
        batch = cities_data[i:i+batch_size]
        data_to_insert = []

        for city in batch:
            data_to_insert.append((
                city.get('id'),
                city.get('name'),
                city.get('state_id'),
                city.get('state_code'),
                city.get('country_id'),
                city.get('country_code'),
                city.get('latitude'),
                city.get('longitude'),
                city.get('wikiDataId')
            ))

        execute_batch(cursor, insert_query, data_to_insert, page_size=1000)
        conn.commit()

        progress = min(i + batch_size, total)
        print(f"Progress: {progress}/{total} cities imported ({(progress/total*100):.1f}%)")

    print(f"Imported all {total} cities successfully!")


def main():
    global DB_PASSWORD

    if len(sys.argv) < 2:
        print("Usage: python3 import_cities_to_supabase.py <your_supabase_password>")
        sys.exit(1)

    DB_PASSWORD = sys.argv[1]

    try:
        # Connect to Supabase
        print("Connecting to Supabase...")
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        print("Connected successfully!")

        # Create tables
        create_tables(conn)

        # Download and import countries
        countries_data = download_json_data(COUNTRIES_URL)
        import_countries(conn, countries_data)

        # Download and import states
        states_data = download_json_data(STATES_URL)
        import_states(conn, states_data)

        # Download and import cities
        cities_data = download_json_data(CITIES_URL)
        import_cities(conn, cities_data)

        print("\n✅ All data imported successfully!")
        print(f"Total: {len(countries_data)} countries, {len(states_data)} states, {len(cities_data)} cities")

        conn.close()

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
