-- ==============================================================================
-- ARCHIVO: seed.sql
-- DESCRIPCIÓN: Carga de Datos de Prueba.
-- MOTIVO: Llenar la base de datos con información ficticia pero realista para realizar pruebas.
-- AUTOR: Marcos Araya Morales
-- APOYO: Inteligencia Artificial (Gemini 3 de Google)
-- ==============================================================================

-- 1. LIMPIEZA Y REINICIO
-- TRUNCATE: Borra todo el contenido de las tablas rápidamente.
-- RESTART IDENTITY: Reinicia los contadores de ID a 1 (para comenzar ordenados).
-- CASCADE: Elimina también los datos relacionados en otras tablas (ej: si borro usuarios, se borran sus pedidos).
TRUNCATE TABLE usuarios, categorias, productos, stock_de_productos, pedidos, detalle_pedidos RESTART IDENTITY CASCADE;

-- ==============================================================================
-- 2. USUARIOS (1 Admin + 5 Clientes)
-- ==============================================================================
INSERT INTO usuarios (nombre, email, hash_password, rol) VALUES
('Super Admin', 'admin@techzone.com', 'admin_secret_pass', 'admin'), -- ID 1
('Juan Perez', 'juan.perez@gmail.com', 'pass123', 'cliente'),        -- ID 2
('Maria Gonzalez', 'maria.gonzalez@hotmail.com', 'secure456', 'cliente'), -- ID 3
('Carlos Ruiz', 'carlos.dev@tech.com', 'code789', 'cliente'),        -- ID 4
('Laura Fernandez', 'laura.f@outlook.com', 'shoplover', 'cliente'),  -- ID 5
('Pedro Pascal', 'pedro@mandalorian.com', 'beskar123', 'cliente');   -- ID 6

-- ==============================================================================
-- 3. CATEGORÍAS (6 Categorías principales)
-- ==============================================================================
INSERT INTO categorias (nombre, descripcion) VALUES
('Laptops', 'Portátiles de alto rendimiento, ultrabooks y gaming'), -- ID 1
('Smartphones', 'Teléfonos móviles Android e iOS'),                -- ID 2
('Componentes PC', 'Procesadores, tarjetas de video, RAM'),        -- ID 3
('Periféricos', 'Teclados, mouse, webcams'),                       -- ID 4
('Monitores', 'Pantallas 4K, Ultrawide y Gaming'),                 -- ID 5
('Audio', 'Auriculares, micrófonos y parlantes');                  -- ID 6

-- ==============================================================================
-- 4. PRODUCTOS (20 Items)
-- Nota: Solo definimos el catálogo. El stock va en la siguiente tabla.
-- ==============================================================================
INSERT INTO productos (nombre, descripcion, precio, categoria_id) VALUES
-- Laptops (ID Cat: 1)
('MacBook Pro M3', '14 pulgadas, 16GB RAM, 512GB SSD', 189900, 1),      -- ID 1
('Dell XPS 15', 'Pantalla OLED, i9 13th Gen, 32GB RAM', 210000, 1),     -- ID 2
('Lenovo Legion 5', 'Gaming Laptop, RTX 4060, 16GB RAM', 125050, 1),    -- ID 3

-- Smartphones (ID Cat: 2)
('iPhone 15 Pro', 'Titanio natural, 256GB', 119900, 2),                 -- ID 4
('Samsung Galaxy S24 Ultra', 'AI Phone, 512GB, Pen incluido', 129900, 2), -- ID 5
('Google Pixel 8', 'Android Puro, Cámara IA', 69900, 2),                -- ID 6

-- Componentes PC (ID Cat: 3)
('NVIDIA RTX 4090', 'Tarjeta gráfica 24GB VRAM', 169900, 3),            -- ID 7
('Intel Core i9-14900K', 'Procesador 24 núcleos', 58900, 3),            -- ID 8
('AMD Ryzen 7 7800X3D', 'El mejor procesador para gaming', 44900, 3),   -- ID 9
('Corsair Vengeance 32GB', 'DDR5 6000MHz RGB', 12999, 3),               -- ID 10
('Samsung 990 Pro 2TB', 'SSD NVMe M.2 Gen4', 16950, 3),                 -- ID 11

-- Periféricos (ID Cat: 4)
('Logitech MX Master 3S', 'Mouse ergonómico productividad', 9900, 4),   -- ID 12
('Keychron K2 Pro', 'Teclado mecánico inalámbrico', 11000, 4),          -- ID 13
('Logitech C920', 'Webcam HD 1080p', 6500, 4),                          -- ID 14

-- Monitores (ID Cat: 5)
('LG UltraGear 27"', 'Monitor 144Hz 1ms IPS', 29999, 5),                -- ID 15
('Dell UltraSharp 32"', 'Monitor 4K USB-C Hub', 75000, 5),              -- ID 16
('Samsung Odyssey G9', 'Monitor Super Ultrawide 49"', 119900, 5),       -- ID 17

-- Audio (ID Cat: 6)
('Sony WH-1000XM5', 'Auriculares con cancelación de ruido', 34800, 6),  -- ID 18
('AirPods Pro 2', 'USB-C, Cancelación activa', 24900, 6),               -- ID 19
('Blue Yeti X', 'Micrófono USB para streaming', 16999, 6);              -- ID 20

-- ==============================================================================
-- 5. STOCK DE PRODUCTOS
-- Aquí definimos cantidades. Ponemos algunos "Bajos" para probar alertas.
-- ==============================================================================
INSERT INTO stock_de_productos (producto_id, cantidad, stock_minimo) VALUES
(1, 10, 5),  -- MacBook
(2, 5, 5),   -- Dell XPS (STOCK BAJO - ALERTA POTENCIAL)
(3, 15, 5),
(4, 50, 10),  -- iPhone (Mucho stock)
(5, 20, 5),
(6, 25, 10),
(7, 2, 5),   -- RTX 4090 (STOCK CRÍTICO - Solo 2)
(8, 10, 5),
(9, 8, 10),
(10, 100, 20), -- RAM (Mucho stock)
(11, 40, 5),
(12, 30, 5),
(13, 12, 5),
(14, 25, 5),
(15, 10, 10),
(16, 4, 5),   -- Monitor Dell (STOCK BAJO)
(17, 3, 5),   -- Monitor Samsung (STOCK BAJO)
(18, 15, 5),
(19, 60, 10),
(20, 8, 10);

-- ==============================================================================
-- 6. PEDIDOS Y DETALLES (Historial de pruebas)
-- ==============================================================================

-- PEDIDO 1: Juan Perez (ID 2) compró una Laptop y un Mouse. ESTADO: PAGADO.
-- El stock ya debería reflejar esta venta si el sistema fuera vivo, pero en seed 
-- asumimos que el stock insertado arriba es el *actual*.
INSERT INTO pedidos (usuario_id, estado) VALUES (2, 'pagado'); -- ID 1
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1, 3, 1, 125050), -- Lenovo Legion (Precio real del catalogo)
(1, 12, 1, 9900);  -- Mouse MX Master

-- PEDIDO 2: Maria Gonzalez (ID 3) tiene un pedido PENDIENTE.
INSERT INTO pedidos (usuario_id, estado) VALUES (3, 'pendiente'); -- ID 2
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(2, 4, 2, 119900); -- 2 iPhones 15 Pro

-- PEDIDO 3: Carlos Ruiz (ID 4) compró componentes. ESTADO: PAGADO.
INSERT INTO pedidos (usuario_id, estado) VALUES (4, 'pagado'); -- ID 3
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(3, 9, 1, 44900),  -- Ryzen 7
(3, 11, 1, 16950); -- SSD Samsung

-- PEDIDO 4: Pedro Pascal (ID 6) intentó comprar la RTX 4090 pero CANCELÓ.
INSERT INTO pedidos (usuario_id, estado) VALUES (6, 'cancelado'); -- ID 4
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(4, 7, 1, 169900); -- RTX 4090

-- PEDIDO 5: Laura (ID 5) recién está armando carrito. ESTADO: INGRESADO.
INSERT INTO pedidos (usuario_id, estado) VALUES (5, 'ingresado'); -- ID 5
-- (Sin detalles aún, carrito vacío o en proceso)

-- Verificación final de datos cargados:
SELECT count(*) as total_usuarios FROM usuarios;    
SELECT count(*) as total_productos FROM productos;
SELECT count(*) as total_stock_records FROM stock_de_productos; 
SELECT count(*) as total_pedidos FROM pedidos;
SELECT count(*) as total_detalle_pedidos FROM detalle_pedidos;