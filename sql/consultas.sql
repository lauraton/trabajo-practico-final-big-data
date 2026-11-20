-- 1. Total recaudado por ciudad, de mayor a menor
SELECT ciudad, SUM(total) AS total_recaudado
FROM tabla_final
GROUP BY ciudad
ORDER BY total_recaudado DESC;

-- 2. Noches reservadas por mes de checkin. DATE_TRUNC agrupa por mes y LIMIT 6 deja los primeros 6 meses
SELECT DATE_TRUNC('month', fecha_checkin) AS mes,
SUM(noches) AS noches_reservadas
FROM tabla_final
GROUP BY mes
ORDER BY mes
LIMIT 6;

-- 3. Total promedio por reserva según tipo de habitación
SELECT tipo_habitacion, AVG(total) AS total_promedio
FROM tabla_final
GROUP BY tipo_habitacion
ORDER BY total_promedio DESC;

-- 4. Cantidad de reservas por canal. No lleva LIMIT 1 porque booking y telefono empatan en 628
SELECT canal, COUNT(*) AS total_reservas
FROM tabla_final
GROUP BY canal
ORDER BY total_reservas DESC;

-- 5. Estadía promedio en noches por país
SELECT pais, AVG(noches) AS estadia_promedio
FROM tabla_final
GROUP BY pais
ORDER BY estadia_promedio DESC;
