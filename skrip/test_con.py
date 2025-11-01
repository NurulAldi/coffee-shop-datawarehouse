from sqlalchemy import create_engine, text

DATABASE_URL = "postgresql://admin:postgres@localhost:55432/warehouse_kopi"

try:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT version();"))
        print("Connected to:", result.scalar())
except Exception as e:
    print("Connection failed: ", e)