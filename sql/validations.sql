-- Evaluamos cada fila y guardamos el motivo del rechazo (NULL = fila valida).
-- El CASE se detiene en la primera regla que falla.

-- tengo q evaluar cada fila y guardar el por qué del rechazo (ACORDARSE)
--  
CREATE OR REPLACE TABLE reservas_evaluadas AS
SELECT
    *,
    CASE
        -- sacamos los id repetidos (nos quedamos con los primeros nomas)
        WHEN ROW_NUMBER() OVER (PARTITION BY id_reserva ORDER BY rowid) > 1
            THEN 'id_duplicado'

        -- las fechas tienen que ser válidas (YYYY-MM-DD)
        WHEN TRY_CAST(fecha_reserva AS DATE) IS NULL
            THEN 'fecha_reserva_invalida'

        -- si fecha_checkin es vacía entonces es inválido
        WHEN TRY_CAST(fecha_checkin AS DATE) IS NULL
            THEN 'fecha_checkin_invalida'

        -- bueno lo mismo que los anteriores con las fechas inválidas
        WHEN TRY_CAST(fecha_checkout AS DATE) IS NULL
            THEN 'fecha_checkout_invalida'

        -- el checkout tiene que ser despues del checkin
        WHEN TRY_CAST(fecha_checkout AS DATE) <= TRY_CAST(fecha_checkin AS DATE)
            THEN 'checkout_antes_de_checkin'

        -- por si el pais es nulo o vacio (TRIM() quita los espacios)
        WHEN pais IS NULL OR TRIM(pais) = ''
            THEN 'pais_nulo'

        -- huéspedes tiene que ser un numero mayor a 0
        WHEN TRY_CAST(huespedes AS INTEGER) IS NULL
            OR TRY_CAST(huespedes AS INTEGER) <= 0
            THEN 'huespedes_invalido'

        -- precio_noche tiene que ser numerico y mayor a 0
        -- (los que vienen con coma, como "66,00", fallan acá)
        WHEN TRY_CAST(precio_noche AS DOUBLE) IS NULL
            OR TRY_CAST(precio_noche AS DOUBLE) <= 0
            THEN 'precio_invalido'

        -- noches nulas o menores o iguales a 0
        WHEN TRY_CAST(noches AS INTEGER) IS NULL
            OR TRY_CAST(noches AS INTEGER) <= 0
            THEN 'noches_invalido'

        -- total nulo o no numerico da invalidez
        WHEN TRY_CAST(total AS DOUBLE) IS NULL
            THEN 'total_invalido'

        WHEN tipo_habitacion NOT IN ('simple', 'doble', 'suite')
            THEN 'tipo_habitacion_invalido'

        WHEN canal NOT IN ('web_propia', 'booking', 'agencia', 'telefono')
            THEN 'canal_invalido'

        WHEN hotel <> TRIM(hotel) OR hotel = UPPER(hotel)
            THEN 'hotel_sin_normalizar'

        ELSE NULL
    END AS motivo_rechazo
FROM raw_reservas;

-------------------------------------------------------------------------

CREATE OR REPLACE TABLE validos AS
SELECT * EXCLUDE (motivo_rechazo)
FROM reservas_evaluadas
WHERE motivo_rechazo IS NULL;

-------------------------------------------------------------------------

CREATE OR REPLACE TABLE rechazados AS
SELECT *
FROM reservas_evaluadas
WHERE motivo_rechazo IS NOT NULL;