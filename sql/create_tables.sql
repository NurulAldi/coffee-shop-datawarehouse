CREATE TABLE IF NOT EXISTS dim_produk (
    product_id INT PRIMARY KEY,
    product_category TEXT,
    product_type TEXT,
    product_detail TEXT,
    current_unit_price NUMERIC (10,2)
);

CREATE TABLE IF NOT EXISTS dim_toko (
    store_id INT PRIMARY KEY,
    store_location TEXT
);

CREATE TABLE IF NOT EXISTS dim_waktu (
    time_id SERIAL PRIMARY KEY,
    transaction_date DATE,
    transaction_time TIME,
    day INT,
    month INT,
    month_name TEXT,
    year INT,
    day_name TEXT,
    hour INT
);

CREATE TABLE IF NOT EXISTS fact_penjualan (
    fact_id SERIAL PRIMARY KEY,
    transaction_id INT,
    product_id INT REFERENCES dim_produk(product_id),
    time_id INT REFERENCES dim_waktu(time_id),
    store_id INT REFERENCES dim_toko(store_id),
    qty INT,
    unit_price NUMERIC(10,2),
    line_total NUMERIC(12,2)
);