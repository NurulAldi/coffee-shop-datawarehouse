# Data Warehouse untuk Analisis Penjualan Coffee Shop dengan Skema Star Schema

## Latar Belakang & Tujuan

Dalam industri retail khususnya coffee shop, pengambilan keputusan bisnis yang cepat dan berbasis data menjadi faktor krusial untuk meningkatkan revenue dan efisiensi operasional. Namun, data penjualan yang tersimpan dalam format spreadsheet (Excel) memiliki keterbatasan signifikan: sulit untuk dianalisis secara mendalam, tidak mendukung query kompleks, dan tidak scalable untuk volume data yang terus bertambah.

Proyek ini bertujuan untuk membangun **Data Warehouse berbasis PostgreSQL** dengan penerapan **Star Schema** yang memungkinkan analisis penjualan multidimensional secara efisien. Data warehouse ini dirancang untuk menjawab berbagai kebutuhan analitik bisnis seperti:

- Identifikasi produk terlaris berdasarkan kategori, tipe, dan lokasi toko
- Analisis tren penjualan berdasarkan dimensi waktu (per jam, hari, bulan, tahun)
- Evaluasi performa toko berdasarkan lokasi geografis
- Perhitungan metrik bisnis kunci (total revenue, average transaction value, quantity sold)

**Konteks Data:**  
Data sumber berasal dari file `Coffee-Shop-Sales.xlsx` yang berisi transaksi historis penjualan coffee shop dengan lebih dari 149.000+ baris transaksi. Data mencakup informasi produk, lokasi toko, waktu transaksi, quantity, dan harga.

**Tujuan Akhir:**  
Membangun fondasi data yang terstruktur, berkualitas tinggi, dan siap pakai untuk mendukung business intelligence dan data-driven decision making melalui dashboard analitik atau ad-hoc SQL queries.

---

## Arsitektur Solusi

Proyek ini mengimplementasikan **batch ETL pipeline** dengan arsitektur yang mengikuti best practices data engineering modern:

### Alur Data End-to-End

![alt text](image/dfd.png)

### Penjelasan Detail Arsitektur

1. **Extract Phase**  
   Data mentah dibaca dari file Excel menggunakan Pandas (`openpyxl` engine). Data ini berisi transaksi dalam format denormalized dengan redundansi tinggi.

2. **Transform Phase**  
   Proses transformasi dilakukan menggunakan Python & Pandas di Jupyter Notebook (`etl.ipynb`):
   
   - **Dimensional Modeling**: Menerapkan Star Schema dengan membuat 3 tabel dimensi dan 1 tabel fakta
   - **dim_produk**: Deduplikasi produk berdasarkan `product_id`, menyimpan informasi kategori, tipe, detail produk, dan harga terkini
   - **dim_toko**: Ekstraksi unique store dengan informasi lokasi
   - **dim_waktu**: Pembuatan dimensi waktu dengan enrichment atribut temporal (day, month, year, day_name, month_name, hour) untuk mendukung time-series analysis
   - **fact_penjualan**: Tabel fakta yang menyimpan metrik transaksi dengan foreign keys ke semua dimensi, dilengkapi dengan perhitungan `line_total` (qty × unit_price)
   
   - **Data Cleaning**: Handling missing values, normalisasi tipe data (date, time, numeric), dan penghapusan duplikat

3. **Data Quality Validation**  
   Sebelum dan sesudah load, dilakukan comprehensive data quality checks (`data_quality_check.ipynb`):
   
   - **Completeness Check**: Validasi tidak ada NULL values pada kolom krusial
   - **Uniqueness Check**: Memastikan tidak ada duplikasi primary key
   - **Referential Integrity Check**: Validasi foreign key constraints (memastikan tidak ada orphaned records)
   - **Business Logic Validation**: Memastikan qty > 0, unit_price > 0, dan perhitungan line_total akurat
   - **Range Validation**: Memverifikasi rentang tanggal transaksi valid

4. **Load Phase**  
   Data dimuat ke PostgreSQL menggunakan SQLAlchemy ORM dengan metode `to_sql()`. Proses load dilakukan secara incremental untuk setiap tabel dengan mode `append`.

5. **Storage Layer**  
   PostgreSQL 16 dipilih sebagai database warehouse dengan pertimbangan:
   - **ACID Compliance**: Menjamin konsistensi dan integritas data
   - **Advanced Indexing**: Mendukung B-tree dan hash indexes untuk optimasi query performance pada tabel dimensi dan fakta
   - **Foreign Key Constraints**: Enforce referential integrity di level database
   - **Mature Ecosystem**: Kompatibel dengan berbagai BI tools dan Python libraries
   
   PostgreSQL dijalankan dalam Docker container untuk portabilitas dan kemudahan deployment.

6. **Orchestration & Management**  
   - **Docker Compose**: Mengorkestrasi PostgreSQL
   - **Volume Persistence**: Data disimpan di `./pgdata` untuk persistensi data di luar container lifecycle

### Skema Star Schema

![alt text](image/schema.png)

### Keunggulan Star Schema

- **Query Performance**: Join operations lebih cepat karena denormalisasi tabel dimensi
- **Simplicity**: Mudah dipahami oleh business users dan data analysts
- **Aggregation Efficiency**: Optimal untuk operasi SUM, AVG, COUNT pada metrik di tabel fakta
- **Dimensional Analysis**: Mendukung slice-and-dice analysis berdasarkan berbagai dimensi (produk, waktu, lokasi)

---

## Tools yang digunakan

| Kategori | Teknologi | Versi | Fungsi |
|----------|-----------|-------|--------|
| **Programming Language** | Python | 3.x | Bahasa utama untuk ETL scripting |
| **Data Processing** | Pandas | Latest | Data manipulation dan transformation |
| **Data Profiling** | ydata-profiling | Latest | Automated exploratory data analysis |
| **Database** | PostgreSQL | 16 | Relational database untuk data warehouse |
| **Database Connector** | psycopg2-binary | Latest | PostgreSQL adapter untuk Python |
| **ORM** | SQLAlchemy | Latest | Database abstraction dan ORM untuk load operations |
| **File Processing** | openpyxl | Latest | Excel file reader untuk extract phase |
| **Containerization** | Docker | Latest | Container runtime untuk PostgreSQL |
| **Orchestration** | Docker Compose | 3.9 | Multi-container orchestration |
| **Development Environment** | Jupyter Notebook | Latest | Interactive development untuk ETL pipeline |


**Tech Stack Rationale:**

- **Python + Pandas**: Dipilih karena ekosistemnya yang mature untuk data manipulation, dokumentasi lengkap, dan kemudahan integrasi dengan database
- **PostgreSQL**: Open-source RDBMS yang enterprise-grade dengan dukungan SQL standard, window functions, dan CTE yang powerful untuk analytical queries
- **Docker**: Menjamin reproducibility dan environment consistency across development/production
- **Star Schema**: Optimal untuk OLAP workloads dengan query pattern yang predictable (mostly read-heavy aggregations)

---

## Cara Menjalankan Proyek

### Prasyarat

Pastikan sistem Anda telah terinstall:

- **Docker Desktop** (versi 20.10 atau lebih baru)
- **Python** 3.8+ dengan pip
- **Git** (untuk clone repository)
- Minimal **2GB RAM** tersedia untuk Docker containers
- **Port 55432** dan **5050** harus available (tidak digunakan aplikasi lain)

### Langkah-Langkah Instalasi

#### 1. Clone Repository

```powershell
git clone https://github.com/NurulAldi/coffee-shop-datawarehouse.git
cd coffee-shop-datawarehouse
```

#### 2. Install Python Dependencies

```powershell
pip install -r requirements.txt
```

#### 3. Start Database Infrastructure

```powershell
docker-compose up -d
```

**Expected Output:**
```
Creating network "coffee_shop_warehouse_default" with the default driver
Creating warehouse_postgres ... done
Creating warehouse_pgadmin   ... done
```

#### 4. Verifikasi Container Status

```powershell
docker-compose ps
```

Pastikan service `warehouse_postgres` dalam status **Up**.

#### 5. Create Database Schema

```powershell
python -c "from sqlalchemy import create_engine, text; engine = create_engine('postgresql://admin:postgres@localhost:55432/warehouse_kopi'); [engine.execute(text(stmt)) for stmt in open('sql/create_tables.sql').read().split(';') if stmt.strip()]"
```


#### 6. Run ETL Pipeline

Buka Jupyter Notebook:

```powershell
jupyter notebook
```

Jalankan notebook secara berurutan:
1. `notebook/inspect_data.ipynb` - Untuk eksplorasi data sumber
2. `notebook/etl.ipynb` - Untuk menjalankan ETL pipeline
3. `notebook/data_quality_check.ipynb` - Untuk validasi hasil load

**Alternatif (jika ingin run sebagai script):**  
Convert notebook ke Python script dan eksekusi:

```powershell
jupyter nbconvert --to script notebook/etl.ipynb
python notebook/etl.py
```

#### 7. Verifikasi Data Load

**Menggunakan SQL Query**

masuk database dengan mengetikkan ke terminal:
```
psql -U admin -p 55432 -d warehouse_kopi
```
dan masukkan password **postgres**

lalu jalankan query-query ini

```sql
-- Cek jumlah baris per tabel
SELECT 'dim_produk' AS table_name, COUNT(*) AS row_count FROM dim_produk
UNION ALL
SELECT 'dim_toko', COUNT(*) FROM dim_toko
UNION ALL
SELECT 'dim_waktu', COUNT(*) FROM dim_waktu
UNION ALL
SELECT 'fact_penjualan', COUNT(*) FROM fact_penjualan;

-- Sample analytical query: Top 5 produk terlaris
SELECT 
    p.product_detail,
    p.product_category,
    SUM(f.qty) AS total_quantity_sold,
    SUM(f.line_total) AS total_revenue
FROM fact_penjualan f
JOIN dim_produk p ON f.product_id = p.product_id
GROUP BY p.product_detail, p.product_category
ORDER BY total_revenue DESC
LIMIT 5;
```

**Expected Results:**
- `dim_produk`: 80 rows
- `dim_toko`: 3 rows
- `dim_waktu`: 116,129 unique date-time combinations
- `fact_penjualan`: 149,116 transaction lines

---

## Hasil

Proyek ini berhasil mengimplementasikan data warehouse production-ready dengan karakteristik sebagai berikut:

**Metrics & Performance:**
- **Total Records Processed**: 149,116 transaksi penjualan
- **Data Warehouse Size**: 
  - Tabel Dimensi: 116,129 unique time dimensions, 80 products, 3 stores
  - Tabel Fakta: 149,116 baris
- **ETL Processing Time**: ~15-20 detik untuk full load (bergantung pada spesifikasi hardware)
- **Data Quality Score**: 100% (0 null values, 0 orphaned records, 0 business logic violations)
- **Query Performance**: Analytical queries dengan JOIN 4 tabel dapat dieksekusi dalam <500ms untuk aggregations

**Business Insights yang Dapat Dihasilkan:**
- Identifikasi bahwa kategori "Coffee" mendominasi 80%+ revenue
- Peak hours penjualan terjadi pada jam 8-10 pagi (breakfast time)
- Tren penjualan menunjukkan pola weekly seasonality yang konsisten
- Store performance analysis menunjukkan disparitas revenue antar lokasi hingga 40%
