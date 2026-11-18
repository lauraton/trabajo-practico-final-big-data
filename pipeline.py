from pathlib import Path
import duckdb

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
SQL_DIR = BASE_DIR / "sql"
DB_PATH = BASE_DIR / "viajaya.duckdb"


def read_sql(filename):
    return (SQL_DIR / filename).read_text(encoding="utf-8")


def count(con, table):
    return con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]


def extract():
    con = duckdb.connect(str(DB_PATH))
    con.execute(read_sql("extract.sql"), [str(DATA_DIR / "reservas.csv")])
    print("Filas cargadas en raw_reservas:", count(con, "raw_reservas"))
    con.close()


def validate():
    con = duckdb.connect(str(DB_PATH))
    con.execute(read_sql("validations.sql"))
    print("Valores validos:", count(con, "validos"))
    print("Valores rechazados:", count(con, "rechazados"))
    con.close()


if __name__ == "__main__":
    extract()
    validate()