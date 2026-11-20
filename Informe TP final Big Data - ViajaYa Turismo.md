# Informe TP final Big Data - ViajaYa Turismo

Integrantes: Lautaro Nicolás Villalba y Bautista Berenfeld. Tema 10. Fecha: 20/11/2026.

Problemas encontrados en el CSV: 75 filas repetidas, 400 reservas con fechas en formato dd/mm/aa y 75 con el checkout antes del checkin. Tambien había 100 reservas sin pais, 100 con huespedes negativos, 125 con el precio escrito con coma, 125 sin noches, 125 sin total y 200 con el hotel en mayusculas, 134 con espacios de mas.

Registros rechazados por regla (cada fila se cuenta en la primera regla que no cumple):

Registros rechazados por regla. Cada fila se cuenta solo en la primera regla que no cumple.

- id_duplicado: 145
- fecha_reserva_invalida: 0
- fecha_checkin_invalida: 195
- fecha_checkout_invalida: 195
- checkout_antes_de_checkin: 71
- pais_nulo: 98
- huespedes_invalido: 97
- precio_invalido: 122
- noches_invalido: 119
- total_invalido: 123
- tipo_habitacion_invalido: 0
- canal_invalido: 0
- hotel_sin_normalizar: 196
- Total: 1361

Quedaron 1214 filas validas y 1361 rechazadas, que eran 1286 reservas distintas porque la columna que guardaba los ids duplicados tiene todas las copias. Con pandas corregimos esos problemas y recuperamos esos datos en la columna rechazados_limpios. Las 75 con el checkout antes del checkin no se pudieron recuperar. tabla_final quedo con 2425 reservas, sin duplicados.

Respuestas a las preguntas (consultas en sql/consultas.sql, sobre tabla_final):

1. Se recaudo por ciudad:
   - Salta: 266.005,31 USD
   - Cusco: 259.409,74 USD
   - Punta del Este: 249.767,11 USD
   - Bariloche: 245.857,28 USD
   - Cartagena: 232.298,90 USD
   - Mendoza: 229.007,93 USD
   - Florianopolis: 199.438,75 USD

2. Las noches reservadas por mes de checkin en los primeros 6 meses de 2024 fueron:
   - Enero: 535
   - Febrero: 537
   - Marzo: 577
   - Abril: 480
   - Mayo: 502
   - Junio: 623

3. El total promedio por reserva segun el tipo de habitacion es:
   - Suite: 1.109,92 USD
   - Doble: 583,31 USD
   - Simple: 355,80 USD

4. Los canales que concentran mas reservas son booking y telefono, empatados con 628 reservas cada uno. siguen web propia con 598 y agencia con 571.

5. La estadia promedio por pais es:
   - Uruguay: 5,56 noches
   - Colombia: 5,56 noches
   - Argentina: 5,46 noches
   - Brasil: 5,34 noches
   - Peru: 5,31 noches
