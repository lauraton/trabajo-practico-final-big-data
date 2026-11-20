from pathlib import Path

import duckdb
import pandas as pd

# Rutas del proyecto, armadas a partir de la carpeta de este archivo
BASE_DIR = Path(__file__).resolve().parent
# Carpeta con el CSV original, que no se modifica
DATA_DIR = BASE_DIR / "datos"
# Carpeta donde se guarda el CSV de los rechazados limpios
OUTPUT_DIR = BASE_DIR / "output"
# Carpeta con los archivos .sql
SQL_DIR = BASE_DIR / "sql"


# read_sql: lee un archivo .sql y devuelve su contenido para ejecutarlo en DuckDB
def read_sql(filename: str):
    try:
        path = SQL_DIR / filename
        return path.read_text(encoding="utf-8")
    except Exception as e:
        print("Ocurrio un error al leer el sql", e)
        raise e


# count: devuelve la cantidad de filas de una tabla para mostrarla por consola
def count(con, table):
    try:
        return con.execute(f"""
        SELECT COUNT(*) FROM {table}
        """).fetchone()
    except Exception as e:
        raise e


# extract: carga el CSV sin cambios en raw_reservas para conservar los datos originales
def extract(con):
    print("######### Extraccion #############")
    con.execute(
        read_sql(filename="extract.sql"), [str(DATA_DIR / "reservas.csv")]
    )
    print("Valores extraidos: ", count(con, "raw_reservas"))


# validate: aplica las reglas de validations.sql y separa las reservas en validos y rechazados
def validate(con):
    print("############## Validacion ################")
    con.execute(read_sql(filename="validations.sql"))
    print("Valores rechazados: ", count(con, "rechazados"))
    print("Valores validos: ", count(con, "validos"))


# clean: corrige los rechazados con pandas y los guarda en rechazados_limpios para recuperarlos
def clean(con):
    print("############## Limpieza ################")
    # Trae los rechazados como DataFrame
    df = con.execute("SELECT * FROM rechazados").df()
    # Cada ciudad con su país, tomado de los válidos, para completar el país que falta
    ciudades = con.execute("SELECT DISTINCT ciudad, pais FROM validos").df()

    # hotel: quita los espacios sobrantes y pasa el nombre a minúsculas para unificarlo
    df["hotel"] = df["hotel"].str.strip().str.lower()
    # Vuelve a escribir cada hotel con su nombre correcto
    df["hotel"] = df["hotel"].replace({
        "gran plaza": "Gran Plaza",
        "hotel andino": "Hotel Andino",
        "posada del sol": "Posada del Sol",
        "costa azul": "Costa Azul",
        "mirador resort": "Mirador Resort"
    })

    # precio_noche: cambia la coma por punto en los precios que la tenían
    df["precio_noche"] = df["precio_noche"].replace({
        "60,00": "60.00",
        "66,00": "66.00",
        "75,00": "75.00",
        "95,50": "95.50",
        "105,05": "105.05",
        "119,38": "119.38",
        "180,00": "180.00",
        "198,00": "198.00",
        "225,00": "225.00"
    })
    # Convierte el precio a número; si un valor no se puede convertir, queda como NaN
    df["precio_noche"] = pd.to_numeric(df["precio_noche"], errors="coerce")

    # huespedes: pasa a positivo las cantidades negativas
    df["huespedes"] = df["huespedes"].replace({-1: 1, -2: 2, -3: 3, -4: 4})

    # Fechas: las lee como aaaa-mm-dd y las que fallan las completa con el formato dd/mm/aaaa
    df["fecha_checkin"] = pd.to_datetime(df["fecha_checkin"], format="%Y-%m-%d", errors="coerce").fillna(
        pd.to_datetime(df["fecha_checkin"], format="%d/%m/%Y", errors="coerce")
    )
    df["fecha_checkout"] = pd.to_datetime(df["fecha_checkout"], format="%Y-%m-%d", errors="coerce").fillna(
        pd.to_datetime(df["fecha_checkout"], format="%d/%m/%Y", errors="coerce")
    )

    # pais: elimina la columna y la vuelve a traer con el merge por ciudad para completar los vacíos
    df = df.drop(columns=["pais"])
    df = pd.merge(df, ciudades, on="ciudad")

    # noches: se pasa a float porque fillna no puede completar con decimales una columna de enteros
    df["noches"] = df["noches"].astype("float")
    # Completa las noches que faltan con total / precio_noche
    df["noches"] = df["noches"].fillna(df["total"] / df["precio_noche"])
    # total: completa los totales que faltan con noches * precio_noche
    df["total"] = df["total"].fillna(df["noches"] * df["precio_noche"])

    # Descarta las reservas con checkout antes del checkin porque no se pueden corregir
    df = df[df["fecha_checkout"] > df["fecha_checkin"]]
    # Deja una sola reserva por id_reserva
    df = df.drop_duplicates(subset=["id_reserva"])

    # Ordena las columnas igual que en raw_reservas, porque el merge dejó pais al final
    df = df[[
        "id_reserva", "fecha_reserva", "fecha_checkin", "fecha_checkout",
        "hotel", "ciudad", "pais", "tipo_habitacion", "huespedes",
        "noches", "precio_noche", "total", "canal"
    ]]

    # Guarda los limpios en output y los carga en la tabla rechazados_limpios
    df.to_csv(str(OUTPUT_DIR / "rechazados_limpios.csv"), index=False)
    con.execute(
        read_sql(filename="load_clean.sql"), [str(OUTPUT_DIR / "rechazados_limpios.csv")]
    )
    print("Valores limpios: ", count(con, "rechazados_limpios"))


# build_final: ejecuta final.sql para unir validos y rechazados_limpios en tabla_final
def build_final(con):
    print("############## Tabla final ################")
    con.execute(read_sql(filename="final.sql"))
    print("Valores en tabla final: ", count(con, "tabla_final"))


# main: abre la base viajaya.duckdb y ejecuta todos los pasos en orden
def main():
    try:
        con = duckdb.connect(str(BASE_DIR / "viajaya.duckdb"))
        extract(con)
        validate(con)
        clean(con)
        build_final(con)
        con.close()
    except Exception as e:
        print("Error al procesar los datos ", e)


if __name__ == "__main__":
    main()
