CREATE OR REPLACE TABLE reservas_evaluadas AS
SELECT * FROM raw_reservas;

-- motivo_rechazo: empieza en NULL y cada regla guarda su nombre en las filas que no la cumplen
ALTER TABLE reservas_evaluadas
ADD COLUMN motivo_rechazo TEXT;

-- ids_duplicados: ids que aparecen más de una vez, porque id_reserva tiene que ser único
CREATE OR REPLACE TABLE ids_duplicados AS
SELECT id_reserva, COUNT(*) AS veces
FROM raw_reservas
GROUP BY id_reserva
HAVING COUNT(*) > 1;

-- Cada regla marca solo filas sin motivo, así cada fila queda con la primera regla que no cumple

-- Regla 1 - id_duplicado: marca todas las copias de un id repetido
UPDATE reservas_evaluadas AS r
SET motivo_rechazo = 'id_duplicado'
FROM ids_duplicados AS d
WHERE r.id_reserva = d.id_reserva;

-- Regla 2 - fecha_reserva_invalida: fecha de reserva que no se puede convertir a DATE
UPDATE reservas_evaluadas
SET motivo_rechazo = 'fecha_reserva_invalida'
WHERE motivo_rechazo IS NULL
AND TRY_CAST(fecha_reserva AS DATE) IS NULL;

-- Regla 3 - fecha_checkin_invalida: checkin que no se puede convertir a DATE (por ejemplo, dd/mm/aaaa)
UPDATE reservas_evaluadas
SET motivo_rechazo = 'fecha_checkin_invalida'
WHERE motivo_rechazo IS NULL
AND TRY_CAST(fecha_checkin AS DATE) IS NULL;

-- Regla 4 - fecha_checkout_invalida: checkout que no se puede convertir a DATE
UPDATE reservas_evaluadas
SET motivo_rechazo = 'fecha_checkout_invalida'
WHERE motivo_rechazo IS NULL
AND TRY_CAST(fecha_checkout AS DATE) IS NULL;

-- Regla 5 - checkout_antes_de_checkin: el checkout tiene que ser posterior al checkin
UPDATE reservas_evaluadas
SET motivo_rechazo = 'checkout_antes_de_checkin'
WHERE motivo_rechazo IS NULL
AND TRY_CAST(fecha_checkout AS DATE) <= TRY_CAST(fecha_checkin AS DATE);

-- Regla 6 - pais_nulo: el país no puede estar vacío
UPDATE reservas_evaluadas
SET motivo_rechazo = 'pais_nulo'
WHERE motivo_rechazo IS NULL
AND (pais IS NULL OR TRIM(pais) = '');

-- Regla 7 - huespedes_invalido: tiene que haber al menos un huésped
UPDATE reservas_evaluadas
SET motivo_rechazo = 'huespedes_invalido'
WHERE motivo_rechazo IS NULL
AND (huespedes IS NULL OR huespedes <= 0);

-- Regla 8 - precio_invalido: el precio tiene que ser un número mayor a 0 (con coma no se puede convertir)
UPDATE reservas_evaluadas
SET motivo_rechazo = 'precio_invalido'
WHERE motivo_rechazo IS NULL
AND (TRY_CAST(precio_noche AS NUMERIC(10,2)) IS NULL
OR TRY_CAST(precio_noche AS NUMERIC(10,2)) <= 0);

-- Regla 9 - noches_invalido: noches no puede estar vacío, ser 0 ni negativo
UPDATE reservas_evaluadas
SET motivo_rechazo = 'noches_invalido'
WHERE motivo_rechazo IS NULL
AND (noches IS NULL OR noches <= 0);

-- Regla 10 - total_invalido: total no puede estar vacío, ser 0 ni negativo
UPDATE reservas_evaluadas
SET motivo_rechazo = 'total_invalido'
WHERE motivo_rechazo IS NULL
AND (total IS NULL OR total <= 0);

-- Regla 11 - tipo_habitacion_invalido: solo se aceptan simple, doble y suite
UPDATE reservas_evaluadas
SET motivo_rechazo = 'tipo_habitacion_invalido'
WHERE motivo_rechazo IS NULL
AND tipo_habitacion NOT IN ('simple', 'doble', 'suite');

-- Regla 12 - canal_invalido: solo se aceptan web_propia, booking, agencia y telefono
UPDATE reservas_evaluadas
SET motivo_rechazo = 'canal_invalido'
WHERE motivo_rechazo IS NULL
AND canal NOT IN ('web_propia', 'booking', 'agencia', 'telefono');

-- Regla 13 - hotel_sin_normalizar: el hotel tiene que coincidir con uno de los 5 nombres correctos
UPDATE reservas_evaluadas
SET motivo_rechazo = 'hotel_sin_normalizar'
WHERE motivo_rechazo IS NULL
AND hotel NOT IN ('Gran Plaza', 'Hotel Andino', 'Posada del Sol', 'Costa Azul', 'Mirador Resort');

-- validos: filas sin motivo_rechazo, es decir, las que cumplen todas las reglas
CREATE OR REPLACE TABLE validos AS
SELECT * FROM reservas_evaluadas
WHERE motivo_rechazo IS NULL;

-- Se elimina motivo_rechazo de validos porque en esa tabla siempre estaría vacía
ALTER TABLE validos
DROP COLUMN motivo_rechazo;

-- rechazados: filas con motivo_rechazo, que indica qué regla no cumplieron
CREATE OR REPLACE TABLE rechazados AS
SELECT * FROM reservas_evaluadas
WHERE motivo_rechazo IS NOT NULL;
