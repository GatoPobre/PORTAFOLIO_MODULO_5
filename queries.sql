-- ==============================================================================
-- ARCHIVO: queries.sql
-- DESCRIPCIÓN: Consultas para ver los datos (Reportes).
-- MOTIVO: Aprender a extraer información útil de las tablas.
-- AUTOR: Marcos Araya Morales
-- APOYO: Inteligencia Artificial (Gemini 3 de Google)
-- ==============================================================================

-- ==============================================================================
-- 1. Listar todos los productos junto a su categoría y stock actual
-- ==============================================================================
-- JOIN: Es el comando para "Unir" tablas.
-- Aquí unimos Productos con Categorías para ver el nombre (ej: 'Laptops') en lugar del identificador numérico (ID).
SELECT 
    p.nombre AS producto, 
    p.precio, 
    s.cantidad AS stock, 
    c.nombre AS categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
JOIN stock_de_productos s ON p.id = s.producto_id;

-- ==============================================================================
-- 2. Buscar productos por nombre (ejemplo 'Silla' o 'Laptop')
-- ==============================================================================
-- ILIKE: Búsqueda flexible.
-- Encuentra el texto sin importar si está escrito en mayúsculas o minúsculas.
SELECT * FROM productos WHERE nombre ILIKE '%airpods%';

-- ==============================================================================
-- 3. Filtrar productos por categoría (ejemplo 'Laptops')
-- ==============================================================================
SELECT p.nombre, p.precio, c.nombre AS categoria 
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Laptops';

-- ==============================================================================
-- 4. Mostrar los productos asociados a un pedido (ejemplo Pedido ID 1)
-- ==============================================================================
SELECT 
    dp.cantidad, 
    p.nombre, 
    dp.precio_unitario, -- Recordar: Este es el precio histórico
    dp.subtotal
FROM detalle_pedidos dp
JOIN productos p ON dp.producto_id = p.id
WHERE dp.pedido_id = 1;

-- ==============================================================================
-- 5. Calcular el total de un pedido (ejemplo Pedido ID 1)
-- ==============================================================================
-- SUM: Suma todos los valores de una columna.
-- Aprovechamos que el 'subtotal' ya está calculado en la tabla, así que solo debemos sumar esos valores.
-- Más adelante, en un sistema real, este total debería guardarse en la tabla 'pedidos' para evitar cálculos repetidos.
SELECT SUM(subtotal) as total_calculado
FROM detalle_pedidos
WHERE pedido_id = 1;

-- ==============================================================================
-- 6. Identificar productos con stock bajo (usando la columna 'stock_minimo' para definir "bajo")
-- ==============================================================================
SELECT 
    p.nombre, 
    s.cantidad as stock_actual,
	s.stock_minimo as umbral_stock_critico
FROM productos p
JOIN stock_de_productos s ON p.id = s.producto_id
WHERE s.cantidad <= s.stock_minimo
ORDER BY s.cantidad ASC; -- Los más críticos al principio

-- ==============================================================================
--- consultas adicionales para el portafolio (no solicitadas como parte del ejercicio)
-- ==============================================================================
-- 7. Ranking de productos más vendidos (best-sellers)
-- GROUP BY: Agrupa los resultados (ej: junta todas las ventas de un mismo producto para sumarlas).
SELECT 
    p.nombre AS producto,
    c.nombre AS categoria,
    SUM(dp.cantidad) AS unidades_vendidas,
    SUM(dp.subtotal) AS ingreso_generado
FROM detalle_pedidos dp
JOIN pedidos pe ON dp.pedido_id = pe.id
JOIN productos p ON dp.producto_id = p.id
JOIN categorias c ON p.categoria_id = c.id
WHERE pe.estado = 'pagado' -- Importante: Solo contar ventas reales (pagadas)
GROUP BY p.id, p.nombre, c.nombre
ORDER BY unidades_vendidas DESC
LIMIT 10; -- Top 10 productos más vendidos

-- 8. Reporte de "Mejores Clientes" (Clientes VIP)
-- Para identificar quiénes son los que más gastan y compran con mayor frecuencia.
SELECT 
    u.nombre AS cliente,
    -- COUNT(DISTINCT ...): Cuenta elementos únicos.
    -- Si un pedido tiene varios productos, cuenta como 1 solo pedido, no varios.
    COUNT(DISTINCT p.id) AS cantidad_ordenes, 
    -- Sumamos los subtotales de los detalles
    SUM(dp.subtotal) AS total_gastado_historico, 
    -- NULLIF: Evita error de división por cero si el cliente no tiene órdenes.
    ROUND(SUM(dp.subtotal) / NULLIF(COUNT(DISTINCT p.id), 0), 2) AS gasto_promedio
FROM usuarios u
JOIN pedidos p ON u.id = p.usuario_id
JOIN detalle_pedidos dp ON p.id = dp.pedido_id 
WHERE p.estado = 'pagado'
GROUP BY u.id, u.nombre
ORDER BY total_gastado_historico DESC
LIMIT 10;

-- 9. Reporte de Ventas Mensuales (Ingresos por Mes)
-- Utilidad: Es el reporte financiero básico. Permite ver la salud del negocio a lo largo del tiempo.
-- TO_CHAR: Convierte la fecha completa a solo Mes-Año (ej: '02-2026') para poder agrupar.
SELECT 
    TO_CHAR(p.fecha_pedido, 'MM-YYYY') AS mes_anio,
    COUNT(DISTINCT p.id) AS total_pedidos, -- OJO: Usar DISTINCT para no contar varias veces el mismo pedido si tiene varios productos
    SUM(dp.subtotal) AS ingresos_brutos    -- Sumamos el subtotal del detalle
FROM pedidos p
JOIN detalle_pedidos dp ON p.id = dp.pedido_id -- Agregamos el JOIN necesario
WHERE p.estado = 'pagado'
GROUP BY TO_CHAR(p.fecha_pedido, 'MM-YYYY')
ORDER BY mes_anio DESC;