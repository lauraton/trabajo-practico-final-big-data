CREATE OR REPLACE TABLE reservas_unificadas AS
SELECT DISTINCT * FROM reservas_evaluadas;

-- Reemplaza los datos de las rechazadas por los limpios (por id_reserva) y les borra el motivo
UPDATE reservas_unificadas AS u
SET fecha_reserva = l.fecha_reserva,
    fecha_checkin = l.fecha_checkin,
    fecha_checkout = l.fecha_checkout,
    hotel = l.hotel,
    ciudad = l.ciudad,
    pais = l.pais,
    tipo_habitacion = l.tipo_habitacion,
    huespedes = l.huespedes,
    noches = l.noches,
    precio_noche = l.precio_noche,
    total = l.total,
    canal = l.canal,
    motivo_rechazo = NULL
FROM rechazados_limpios AS l
WHERE u.id_reserva = l.id_reserva;

-- Elimina las reservas que no se pudieron limpiar (checkout antes del checkin)
DELETE FROM reservas_unificadas
WHERE motivo_rechazo IS NOT NULL;

-- tabla_final: reservas con los tipos correctos, fechas como DATE y números como INTEGER o NUMERIC
CREATE OR REPLACE TABLE tabla_final AS
SELECT
    id_reserva,
    CAST(fecha_reserva AS DATE) AS fecha_reserva,
    CAST(fecha_checkin AS DATE) AS fecha_checkin,
    CAST(fecha_checkout AS DATE) AS fecha_checkout,
    hotel,
    ciudad,
    pais,
    tipo_habitacion,
    CAST(huespedes AS INTEGER) AS huespedes,
    CAST(noches AS INTEGER) AS noches,
    CAST(precio_noche AS NUMERIC(10,2)) AS precio_noche,
    CAST(total AS NUMERIC(10,2)) AS total,
    canal
FROM reservas_unificadas;
