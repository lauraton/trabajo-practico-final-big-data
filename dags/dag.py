import sys
from datetime import datetime
from pathlib import Path
from airflow.sdk import dag, task
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import pipeline
@task
def extract():
    pipeline.extract()
@task
def validate():
    pipeline.validate()

# declaro que el pipeline se ejecute automáticamente todos los días a las 2am
@dag(
    dag_id="viajaya_etl",
    start_date=datetime(2026, 11, 1),
    schedule="0 2 * * *",
    catchup=False,
)
def viajaya_etl():
    extract() >> validate()


viajaya_etl()