# Coffee Shop Data Warehouse

Data warehouse berbasis star schema untuk analisis penjualan coffee shop. Proyek ini menyiapkan database PostgreSQL via Docker, ETL sederhana dari Excel ke CSV, pemuatan data ke tabel dimensi & fakta, serta notebook untuk data quality checks.



- Sumber data: `data/Coffee-Shop-Sales.xlsx`
- Proses ETL (notebook): menghasilkan CSV bersih di `data/cleaned/`
- Target DW: PostgreSQL (port host 55432)
- Skema: Star schema dengan 3 dimensi dan 1 tabel fakta

## Arsitektur dan Komponen

- Docker Compose menjalankan:
	- PostgreSQL 16 (container: `warehouse_postgres`)
		- DB: `warehouse_kopi`
		- User/Password: `admin` / `postgres`
		- Port: host `55432` -> container `5432`
		- Volume data: `./pgdata` -> `/var/lib/postgresql/data`
	- pgAdmin 4 (container: `warehouse_pgadmin`)
		- UI: http://localhost:5050
		- Login: `admin@warehouse.local` / `admin123`

File terkait:
- `docker-compose.yml` – orkestrasi container DB & pgAdmin
- `sql/create_tables.sql` – definisi tabel data warehouse
- `requirements.txt` – dependensi Python untuk ETL/validasi
- `notebook/` – ETL dan data quality checks
- `data/cleaned/` – hasil ETL siap muat ke DW
- `skrip/test_con.py` – skrip uji koneksi DB via SQLAlchemy



## Skema Data (Star Schema)

Tabel dimensi:
- `dim_produk`
	- `product_id` (PK, INT)
	- `product_category` (TEXT)
	- `product_type` (TEXT)
	- `product_detail` (TEXT)
	- `current_unit_price` (NUMERIC(10,2))
- `dim_toko`
	- `store_id` (PK, INT)
	- `store_location` (TEXT)
- `dim_waktu`
	- `time_id` (PK, SERIAL)
	- `transaction_date` (DATE)
	- `transaction_time` (TIME)
	- `day` (INT)
	- `month` (INT)
	- `month_name` (TEXT)
	- `year` (INT)
	- `day_name` (TEXT)
	- `hour` (INT)

Tabel fakta:
- `fact_penjualan`
	- `fact_id` (PK, SERIAL)
	- `transaction_id` (INT)
	- `product_id` (INT, FK -> `dim_produk.product_id`)
	- `time_id` (INT, FK -> `dim_waktu.time_id`)
	- `store_id` (INT, FK -> `dim_toko.store_id`)
	- `qty` (INT)
	- `unit_price` (NUMERIC(10,2))
	- `line_total` (NUMERIC(12,2))

---

## Prasyarat

- Docker Desktop terbaru (Compose v2)
- Python 3.10+

Install dependensi Python (opsional, untuk notebook/skrip):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```


## Menjalankan Layanan (Docker)

Jalankan database dan pgAdmin:

```powershell
# di folder proyek (yang berisi docker-compose.yml)
docker compose up -d

# melihat status
docker compose ps
```

Akses:
- PostgreSQL: `localhost:55432`

Hentikan layanan:

```powershell
docker compose down
```


## Inisialisasi Skema Database

Setelah container aktif, buat tabel DW menggunakan salah satu opsi berikut:

1) Menggunakan pgAdmin
- Login pgAdmin → Add New Server → isikan:
	- Name: `warehouse_local`
	- Connection → Host: `postgres`, Port: `5432`, Username: `admin`, Password: `postgres`, DB: `warehouse_kopi`
- Buka Query Tool → jalankan isi file `sql/create_tables.sql`

2) Menggunakan psql di dalam container

```powershell
# salin file SQL ke container (opsional, bisa juga copy-paste di psql)
docker cp .\sql\create_tables.sql warehouse_postgres:/create_tables.sql

# eksekusi psql di dalam container
docker exec -it warehouse_postgres psql -U admin -d warehouse_kopi -f /create_tables.sql
```

---

## Memuat Data ke Tabel

Data hasil ETL tersedia di `data/cleaned/`:
- `dim_produk.csv`
- `dim_toko.csv`
- `dim_waktu.csv`
- `fact_penjualan.csv`

Anda bisa memuat data dengan salah satu cara berikut.

1) pgAdmin (UI, paling mudah)
- Klik kanan tabel → Import/Export → Import → Format: CSV → pilih file CSV dari host.
- Centang "Header" dan set delimiter `,` → Jalankan.

2) Python + pandas (memanfaatkan dependensi yang sudah ada)

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://admin:postgres@localhost:55432/warehouse_kopi")

for name in ["dim_produk", "dim_toko", "dim_waktu", "fact_penjualan"]:
		df = pd.read_csv(f"data/cleaned/{name}.csv")
		df.to_sql(name, engine, if_exists="append", index=False)
```

3) psql + COPY di dalam container (cepat untuk file besar)

```powershell
# salin semua CSV ke container
foreach ($f in Get-ChildItem .\data\cleaned\*.csv) { docker cp $f.FullName warehouse_postgres:/tmp/$(Split-Path $f -Leaf) }

# jalankan COPY per tabel
$cmds = @(
	"\\COPY dim_produk     FROM '/tmp/dim_produk.csv'     CSV HEADER",
	"\\COPY dim_toko       FROM '/tmp/dim_toko.csv'       CSV HEADER",
	"\\COPY dim_waktu      FROM '/tmp/dim_waktu.csv'      CSV HEADER",
	"\\COPY fact_penjualan FROM '/tmp/fact_penjualan.csv' CSV HEADER"
)
foreach ($c in $cmds) { docker exec -it warehouse_postgres psql -U admin -d warehouse_kopi -c $c }
```

---

## Notebook ETL & Data Quality

- `notebook/etl.ipynb` – ekstraksi dari Excel (`data/Coffee-Shop-Sales.xlsx`), transformasi, dan ekspor ke `data/cleaned/`
- `notebook/data_quality_check.ipynb` – validasi kualitas data, meliputi:
	- ✓ Duplikat tidak ada
	- ✓ Null values tidak ada
	- ✓ Referential integrity antar FK-PK terjaga
	- ✓ Business rules (mis. qty > 0, price > 0)

Menjalankan notebook:

```powershell
.\.venv\Scripts\Activate.ps1
jupyter notebook
```

Buka notebook di browser, jalankan sel berurutan.

---

## Uji Koneksi Database (opsional)

Skrip sederhana tersedia di `skrip/test_con.py`:

```powershell
.\.venv\Scripts\Activate.ps1
python .\skrip\test_con.py
```

Output yang diharapkan (contoh):
```
Connected to: PostgreSQL 16.x on x86_64-pc-linux-gnu, compiled by ...
```

---

## Struktur Proyek

```
coffee_shop_warehouse/
├─ docker-compose.yml
├─ requirements.txt
├─ README.md
├─ data/
│  ├─ Coffee-Shop-Sales.xlsx         # sumber data mentah
│  └─ cleaned/                       # hasil ETL siap muat
│     ├─ dim_produk.csv
│     ├─ dim_toko.csv
│     ├─ dim_waktu.csv
│     └─ fact_penjualan.csv
├─ notebook/
│  ├─ etl.ipynb                      # ETL dari Excel → CSV
│  ├─ inspect_data.ipynb             # eksplorasi awal (opsional)
│  └─ data_quality_check.ipynb       # validasi kualitas data
├─ sql/
│  └─ create_tables.sql              # definisi tabel DW
├─ skrip/
│  └─ test_con.py                    # uji koneksi DB
└─ pgdata/                           # data directory PostgreSQL (volume)
```

---

## Troubleshooting

- Container tidak mau start: pastikan tidak ada service lain di port 55432/5050.
- Tidak bisa login pgAdmin: cek kredensial di `docker-compose.yml`.
- Gagal COPY CSV: pastikan file benar-benar dicopy ke container dan gunakan opsi `CSV HEADER`.
- Insert duplikat/violate FK: jalankan data quality check dan urutkan load: dimensi dulu, lalu fakta.
- Windows PowerShell: gunakan path dengan `\\\\` atau `\\` sesuai contoh; jalankan terminal sebagai Administrator jika perlu.

---

## Rencana Pengembangan (Next Steps)

- Otomasi load data via skrip Python/CLI
- Penjadwalan ETL (mis. via Airflow/cron)
- Materialized views untuk analitik umum
- Dashboard BI (Power BI/Metabase/Superset)

---

## Lisensi

Proyek ini untuk tujuan pembelajaran. Tambahkan file LICENSE jika ingin mendistribusikan secara terbuka.