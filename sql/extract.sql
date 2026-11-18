CREATE OR REPLACE TABLE raw_reservas AS
SELECT * FROM read_csv(?, header = true, delim = ',', all_varchar = true);