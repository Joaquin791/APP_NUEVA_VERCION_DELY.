
-- ============================================================================
-- DELY — B03: Auditoría de la base de datos (SOLO LECTURA)
-- ============================================================================
-- Uso:
--   mysql -h <host> -P <puerto> -u <usuario> -p dely < b03-auditoria-db.sql
-- o copiar cada bloque en phpMyAdmin.
--
-- Esquema canónico: database/init.sql con 4 tablas:
--   usuarios, estados, pedidos, historial_pedidos (+ 6 FKs)
--
-- Tabla `usuarios`:
-- id_usuario, cedula, nombre, apellido, usuario, password_hash,
-- rol, activo, fecha_creacion.
--
-- Roles permitidos: encargado, repartidor.
-- Estados de pedidos: En preparación, En camino, Entregado.
-- El sistema ya no utiliza prioridades.
--
-- Cómo leer los resultados: cada bloque indica lo esperado. Si una consulta
-- falla por tabla o columna inexistente, registrarlo como diferencia entre
-- el código y la base de datos real.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 0) Base actual y lista de tablas (se esperan 4)
-- ----------------------------------------------------------------------------

SELECT DATABASE() AS base_actual;

SELECT TABLE_NAME AS tabla,
       TABLE_ROWS AS filas_aprox,
       ENGINE AS motor
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


-- ----------------------------------------------------------------------------
-- 1) Columnas reales de usuarios
-- Se esperan: id_usuario, cedula, nombre, apellido, usuario,
-- password_hash, rol, activo, fecha_creacion.
-- ----------------------------------------------------------------------------

SHOW COLUMNS FROM usuarios;

SELECT COLUMN_NAME AS columna,
       IS_NULLABLE AS nulo,
       COLUMN_DEFAULT AS por_defecto,
       COLUMN_TYPE AS tipo
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'usuarios'
ORDER BY ORDINAL_POSITION;


-- ----------------------------------------------------------------------------
-- 2) Roles y estados de usuarios
-- Esperado: rol solo encargado/repartidor; activo 0/1.
-- ----------------------------------------------------------------------------

SELECT rol, COUNT(*) AS cantidad
FROM usuarios
GROUP BY rol;

SELECT activo, COUNT(*) AS cantidad
FROM usuarios
GROUP BY activo;


-- ----------------------------------------------------------------------------
-- 3) Claves primarias
-- Se espera una clave primaria por cada una de las 4 tablas.
-- ----------------------------------------------------------------------------

SELECT TABLE_NAME AS tabla,
       COLUMN_NAME AS columna_pk,
       ORDINAL_POSITION AS posicion
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND INDEX_NAME = 'PRIMARY'
ORDER BY tabla, posicion;


-- ----------------------------------------------------------------------------
-- 4) Claves foráneas
-- Se esperan 6:
--   3 en pedidos.
--   3 en historial_pedidos.
-- ----------------------------------------------------------------------------

SELECT CONSTRAINT_NAME AS restriccion,
       TABLE_NAME AS tabla,
       COLUMN_NAME AS columna,
       REFERENCED_TABLE_NAME AS referencia_tabla,
       REFERENCED_COLUMN_NAME AS referencia_columna
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY tabla, ORDINAL_POSITION;

SELECT CONSTRAINT_NAME AS restriccion,
       TABLE_NAME AS tabla,
       UPDATE_RULE AS al_actualizar,
       DELETE_RULE AS al_borrar
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE()
ORDER BY tabla;


-- ----------------------------------------------------------------------------
-- 5) Catálogo de estados
-- Se esperan 3 estados:
-- En preparación, En camino y Entregado.
-- ----------------------------------------------------------------------------

SELECT * FROM estados
ORDER BY id_estado;

SELECT COUNT(*) AS total_estados
FROM estados;


-- ----------------------------------------------------------------------------
-- 6) Volúmenes generales y usuarios inactivos
-- ----------------------------------------------------------------------------

SELECT COUNT(*) AS total_usuarios
FROM usuarios;

SELECT COUNT(*) AS total_pedidos
FROM pedidos;

SELECT COUNT(*) AS total_historial
FROM historial_pedidos;

SELECT COUNT(*) AS usuarios_inactivos
FROM usuarios
WHERE activo = FALSE;


-- ----------------------------------------------------------------------------
-- 7) Unicidad asumida por el backend
-- Se esperan 0 filas en ambas consultas.
-- El alta de usuarios rechaza cédulas y nombres de usuario duplicados.
-- ----------------------------------------------------------------------------

SELECT cedula, COUNT(*) AS veces
FROM usuarios
GROUP BY cedula
HAVING COUNT(*) > 1;

SELECT usuario, COUNT(*) AS veces
FROM usuarios
GROUP BY usuario
HAVING COUNT(*) > 1;


-- ----------------------------------------------------------------------------
-- 8) Coherencia entre pedidos e historial
-- ----------------------------------------------------------------------------

-- Cantidad de pedidos por estado.

SELECT e.nombre AS estado,
       COUNT(*) AS cantidad
FROM pedidos AS p
INNER JOIN estados AS e
    ON e.id_estado = p.id_estado
GROUP BY e.nombre;


-- Historiales que apuntan a pedidos inexistentes.
-- Se esperan 0.

SELECT COUNT(*) AS historial_sin_pedido
FROM historial_pedidos AS h
LEFT JOIN pedidos AS p
    ON p.id_pedido = h.id_pedido
WHERE p.id_pedido IS NULL;


-- Pedidos que tienen un estado inexistente.
-- Se esperan 0.

SELECT COUNT(*) AS pedidos_sin_estado
FROM pedidos AS p
LEFT JOIN estados AS e
    ON e.id_estado = p.id_estado
WHERE e.id_estado IS NULL;


-- ----------------------------------------------------------------------------
-- 9) Comprobación de referencias antiguas a prioridades
-- Se espera que no exista ninguna tabla llamada prioridades.
-- ----------------------------------------------------------------------------

SELECT COUNT(*) AS tablas_prioridades
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'prioridades';


-- ============================================================================
-- FIN DE LA AUDITORÍA B03
-- La estructura esperada corresponde a database/init.sql.
-- ============================================================================
