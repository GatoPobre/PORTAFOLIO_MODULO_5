-- schema.sql 
-- ==============================================================================
-- ARCHIVO: schema.sql
-- DESCRIPCIÓN: Estructura de la Base de Datos (Tablas y Reglas).
-- MOTIVO: Aquí definimos qué datos vamos a guardar y cómo se relacionan entre sí.
-- AUTOR: Marcos Araya Morales
-- APOYO: Inteligencia Artificial (Gemini 3 de Google)
-- FECHA: 08-02-2026
-- ==============================================================================

-- 1. LIMPIEZA PREVENTIVA
-- Borramos las tablas antiguas si existen para comenzar con una base de datos limpia.
-- "CASCADE" significa: "Borra esto y todo lo que dependa de ello" (ej: si borro la tabla usuarios, se borran sus pedidos automáticamente).
DROP TABLE IF EXISTS detalle_pedidos CASCADE;
DROP TABLE IF EXISTS stock_de_productos CASCADE; 
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS categorias CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TYPE IF EXISTS estado_pedido CASCADE;
DROP TYPE IF EXISTS rol_usuario CASCADE;

-- 2. TIPOS DE DATOS PERSONALIZADOS (ENUMS)
-- Un ENUM es una lista definida de opciones permitidas.
-- Ventaja: Evita errores de escritura. Solo permite valores como 'ingresado', 'pendiente', etc.
-- Si intentas guardar algo distinto (ej: 'pagado_ok'), la base de datos mostrará un error.
-- se podria usar un CHECK con VARCHAR, pero el ENUM es más limpio y fácil de mantener para este caso específico.
-- pero se opto por CREATE TYPE por temas de aprendizaje.
CREATE TYPE estado_pedido AS ENUM ('ingresado', 'pendiente', 'pagado', 'cancelado');
CREATE TYPE rol_usuario AS ENUM ('admin', 'cliente');

-- ==============================================================================
-- 3. CREACIÓN DE TABLAS (ESTRUCTURA BASE)
-- ==============================================================================

-- TABLA USUARIOS
CREATE TABLE usuarios (
    -- SERIAL: Es un contador automático (1, 2, 3...). Se genera solo, no es necesario escribirlo.
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL, 
    -- VARCHAR(255): Para guardar la contraseña encriptada (hash), que es una cadena larga de texto.
    -- Usamos VARCHAR para limitar el tamaño máximo por seguridad.
    hash_password VARCHAR(255) NOT NULL, 
    -- DEFAULT: Si no especificamos el rol, se asigna 'cliente' automáticamente.
    -- Usamos el ENUM creado arriba para asegurar que sea un rol válido.
    rol rol_usuario DEFAULT 'cliente',
    -- TIMESTAMPTZ: Guarda la fecha y la hora exacta (incluyendo zona horaria).
    -- DEFAULT CURRENT_TIMESTAMP: Si no indicamos fecha, se registra el momento actual.
    -- Se recomienda usar TIMESTAMPTZ para evitar problemas con zonas horarias en el futuro 
    -- (ej: si la tienda crece y tiene clientes en otros países).
    -- No se uso NOW() porque CURRENT_TIMESTAMP es más estándar y funciona igual en este contexto.
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP 
);

-- TABLA CATEGORIAS
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL, 
    descripcion TEXT
);

-- TABLA PRODUCTOS
-- Aquí guardamos la información descriptiva del producto (Catálogo).
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    -- NUMERIC(10, 2): Usamos esto para valores monetarios. Permite 10 dígitos en total, con 2 decimales.
    -- Es mejor que FLOAT porque es exacto para cálculos financieros (no pierde precisión).
    -- Aunque en Chile no usamos centavos, es buena práctica dejarlo preparado.
    precio NUMERIC(10, 2) NOT NULL, 
    categoria_id INT, 
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- Creamos una columna "activo" para poder desactivar productos sin borrarlos (útil para promociones, temporadas, etc).
    activo BOOLEAN DEFAULT TRUE
);

-- TABLA STOCK_DE_PRODUCTOS
-- Separamos el stock en otra tabla para mantener el orden y mejorar el rendimiento.
-- Así, actualizar la cantidad disponible no bloquea la información del producto (nombre, precio) para otros usuarios.
CREATE TABLE stock_de_productos (
    id SERIAL PRIMARY KEY,
    producto_id INT NOT NULL, 
    cantidad INT NOT NULL,
    -- Nivel de alerta: si baja de este número, avisamos.
    -- Dejamos un valor por defecto de 10, pero se puede ajustar según el producto 
    --(ej: para un producto muy demandado, el mínimo podría ser 20).
    stock_minimo INT DEFAULT 10, 
    ultima_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- TABLA PEDIDOS
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL, 
    fecha_pedido TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    estado estado_pedido DEFAULT 'ingresado'
);

-- TABLA DETALLE_PEDIDOS
CREATE TABLE detalle_pedidos (
    id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL,   
    producto_id INT NOT NULL, 
    cantidad INT NOT NULL,    
    precio_unitario NUMERIC(10, 2) NOT NULL,
    -- COLUMNA CALCULADA AUTOMÁTICAMENTE:
    -- "GENERATED ALWAYS ... STORED": La base de datos realiza la multiplicación (cantidad * precio) automáticamente.
    -- Guarda el resultado por nosotros, evitando errores de cálculo manual.
    subtotal NUMERIC(12, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
);

-- ==============================================================================
-- CAPA 4: RESTRICCIONES (CONSTRAINTS & FKs)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- RESTRICCIONES DE USUARIOS
-- ------------------------------------------------------------------------------
ALTER TABLE usuarios
    ADD CONSTRAINT uq_usuarios_email UNIQUE (email); -- No permite dos usuarios con el mismo correo.

-- ------------------------------------------------------------------------------
-- RESTRICCIONES DE CATEGORIAS
-- ------------------------------------------------------------------------------
ALTER TABLE categorias
    ADD CONSTRAINT uq_categorias_nombre UNIQUE (nombre); -- No permite categorías con nombre repetido.

-- ------------------------------------------------------------------------------
-- RESTRICCIONES DE PRODUCTOS
-- ------------------------------------------------------------------------------
ALTER TABLE productos
    ADD CONSTRAINT chk_productos_precio_positivo CHECK (precio >= 0); -- Evita precios negativos

ALTER TABLE productos
    ADD CONSTRAINT fk_productos_categorias 
    FOREIGN KEY (categoria_id) REFERENCES categorias(id)
     ON UPDATE CASCADE -- Si cambia el ID de la categoría, actualiza los productos automáticamente.
     ON DELETE SET NULL;-- Si borro la categoría, los productos no se borran, quedan "sin categoría".

ALTER TABLE productos
-- Evita nombres de productos duplicados en la misma categoría    
    ADD CONSTRAINT uq_productos_categoria_nombre UNIQUE (categoria_id, nombre); 

-- ------------------------------------------------------------------------------
-- RESTRICCIONES DE STOCK
-- ------------------------------------------------------------------------------
ALTER TABLE stock_de_productos
    ADD CONSTRAINT chk_stock_positivo CHECK (cantidad >= 0); -- Evita stock negativo

ALTER TABLE stock_de_productos
    ADD CONSTRAINT fk_stock_producto 
    FOREIGN KEY (producto_id) REFERENCES productos(id) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE; -- Si borro el producto del catálogo, se borra su stock también.

ALTER TABLE stock_de_productos
    ADD CONSTRAINT uq_stock_producto_unico UNIQUE (producto_id); 

ALTER TABLE stock_de_productos
    ADD CONSTRAINT chk_stock_minimo_positivo CHECK (stock_minimo >= 0); -- Evita stock mínimo negativo

-- ------------------------------------------------------------------------------
-- RESTRICCIONES DE PEDIDOS
-- ------------------------------------------------------------------------------
ALTER TABLE pedidos
    ADD CONSTRAINT fk_pedidos_usuario 
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
     ON UPDATE CASCADE 
     ON DELETE RESTRICT; -- PROTECCIÓN: No te deja borrar un usuario si ya tiene pedidos hechos.

-- ------------------------------------------------------------------------------
-- RESTRICCIONES DE DETALLE_PEDIDOS
-- ------------------------------------------------------------------------------
ALTER TABLE detalle_pedidos
    ADD CONSTRAINT chk_detalle_cantidad_positiva CHECK (cantidad > 0); -- Evita cantidades negativas o cero

ALTER TABLE detalle_pedidos
    ADD CONSTRAINT fk_detalle_pedido 
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) 
    ON UPDATE CASCADE 
    ON DELETE CASCADE; -- Si borro el pedido, se borran sus detalles (productos comprados).

ALTER TABLE detalle_pedidos
    ADD CONSTRAINT fk_detalle_producto 
    FOREIGN KEY (producto_id) REFERENCES productos(id)
    ON UPDATE CASCADE 
    ON DELETE RESTRICT; -- PROTECCIÓN: No puedes borrar un producto si alguien ya lo compró.

ALTER TABLE detalle_pedidos 
ADD CONSTRAINT uq_detalle_pedido_producto 
UNIQUE (pedido_id, producto_id); 
-- Regla: Un producto solo puede aparecer una vez por pedido.
-- Si quieres comprar 2 unidades, aumentas la columna 'cantidad', no agregas otra fila.

-- ==============================================================================
-- 5. ÍNDICES (BÚSQUEDAS RÁPIDAS)
-- Funcionan como el índice de un libro. Sin ellos, la base de datos tendría que leer todo para encontrar un dato.
-- Con el índice, va directo a la información, haciendo que las consultas sean mucho más rápidas.
-- ==============================================================================

-- 1. Índice para Búsquedas de Productos por Nombre
-- Motivo: Para que el buscador de la tienda responda rápido (ej: "Buscar iPhone...").
CREATE INDEX idx_productos_nombre ON productos(nombre);

-- 2. Índice de Foreign Key en Pedidos -> Usuario
-- Motivo: Para encontrar rápidamente todos los pedidos de un usuario.
CREATE INDEX idx_pedidos_usuario_id ON pedidos(usuario_id);

-- 3. Índice de Foreign Key en Detalle -> Pedido
-- Motivo: Para cargar rápidamente los productos de un pedido.
CREATE INDEX idx_detalle_pedido_id ON detalle_pedidos(pedido_id);

-- 4. Índice de Estado del Pedido
-- Motivo: Para reportes administrativos (ej: "Ver todos los pedidos pendientes").
CREATE INDEX idx_pedidos_estado ON pedidos(estado);

-- ==============================================================================
--**********************************************************************************
-- ESTO ES OPCIONAL: PARA REALIZAR LA SIMULACIÓN DE TRANSACCIÓN EN transaction.sql,
-- PODEMOS REALIZARLO DENTRO DE UN BLOQUE DE CÓDIGOS TEMPORAL (DO $$ ... END $$)  
-- O USAR WITH QUERIES (CTEs) PARA HACER PRUEBAS RÁPIDAS.
-- O SIMPLEMENTE EJECUTAR LOS PASOS MANUALMENTE EN EL ORDEN CORRECTO DENTRO DE UNA TRANSACCIÓN.
-- EN TRANSACTION.SQL ESTARAN LOS OTROS PASOS DE LA SIMULACIÓN.
--***********************************************************************************
-- 6. LÓGICA AUTOMÁTICA (TRIGGERS / DISPARADORES)
-- Un Trigger es una acción automática que se ejecuta cuando ocurre un evento (como actualizar una tabla).
-- Aquí lo usamos para descontar el stock automáticamente cuando el estado del pedido cambia a 'pagado'.
-- ==============================================================================

-- Paso A: Crear la FUNCIÓN que contiene la lógica.
-- Esta función contiene las instrucciones de qué hacer cuando se activa el trigger.
CREATE OR REPLACE FUNCTION gestionar_cambio_estado_pedido()
RETURNS TRIGGER AS $$
DECLARE
    -- Variables para usar dentro de la función (debes declarar las que necesites sino te dará error)
    r_detalle RECORD;       -- Variable tipo fila para iterar los productos del pedido
    v_stock_actual INT;     -- Para guardar temporalmente el stock leído
    v_stock_minimo INT;     -- Para guardar temporalmente el stock_minimo leído
BEGIN
    -- ------------------------------------------------------------------
    -- REGLA 1: DESCONTAR STOCK AL PAGAR
    -- Se activa si el estado nuevo es 'pagado' y el anterior NO lo era.
    -- NEW y OLD son palabras reservadas que representan el nuevo y antiguo valor de la fila.
    -- ------------------------------------------------------------------
    IF NEW.estado = 'pagado' AND OLD.estado != 'pagado' THEN
        
        -- Bucle: Recorremos cada producto dentro del pedido
        FOR r_detalle IN SELECT * FROM detalle_pedidos WHERE pedido_id = NEW.id LOOP
            
            -- BLOQUEO DE SEGURIDAD (SELECT ... FOR UPDATE):
            -- Esto "bloquea" momentáneamente el registro del stock de este producto.
            -- Evita conflictos si dos personas intentan comprar el último producto al mismo tiempo exacto.
            SELECT cantidad, stock_minimo INTO v_stock_actual, v_stock_minimo
            FROM stock_de_productos 
            WHERE producto_id = r_detalle.producto_id
            FOR UPDATE; 

            -- Validación 1: ¿Existe el registro de stock?
            IF v_stock_actual IS NULL THEN
                 RAISE EXCEPTION 'Inconsistencia: El producto ID % no tiene inventario inicializado.', r_detalle.producto_id;
            END IF;
            
            -- Validación 2: ¿Hay suficiente cantidad?
            IF v_stock_actual < r_detalle.cantidad THEN
                RAISE EXCEPTION 'Stock insuficiente para producto ID %. Stock: %, Solicitado: %', 
                              r_detalle.producto_id, v_stock_actual, r_detalle.cantidad;
            END IF;

            -- Acción: Restar el stock
            UPDATE stock_de_productos 
            SET cantidad = cantidad - r_detalle.cantidad,
                ultima_actualizacion = CURRENT_TIMESTAMP
            WHERE producto_id = r_detalle.producto_id;

            -- Alerta Informativa (Solo avisa, no detiene la venta)
            IF (v_stock_actual - r_detalle.cantidad) <= v_stock_minimo THEN
                RAISE NOTICE 'ALERTA STOCK: Producto ID % queda con % unidades.', r_detalle.producto_id, (v_stock_actual - r_detalle.cantidad);
            END IF;
            
        END LOOP;
    END IF;

    -- ------------------------------------------------------------------
    -- REGLA 2: DEVOLVER STOCK AL CANCELAR
    -- Si el pedido ya estaba pagado (stock descontado) y se cancela, devolvemos.
    -- ------------------------------------------------------------------
    IF NEW.estado = 'cancelado' AND OLD.estado = 'pagado' THEN
    --
        FOR r_detalle IN SELECT * FROM detalle_pedidos WHERE pedido_id = NEW.id LOOP
            UPDATE stock_de_productos 
            SET cantidad = cantidad + r_detalle.cantidad,
                ultima_actualizacion = CURRENT_TIMESTAMP
            WHERE producto_id = r_detalle.producto_id;
        END LOOP;
        RAISE NOTICE 'Pedido cancelado. Stock restaurado.';
    END IF;

    -- Retornamos NEW para confirmar que el UPDATE del pedido procede.
    -- Si no retornamos NEW, el cambio de estado no se guardaría (sería como si el trigger no existiera).
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Paso B: Crear el TRIGGER
-- El trigger es el "vigilante" que ejecuta la función de arriba cuando cambia el estado.
DROP TRIGGER IF EXISTS trg_actualizar_stock ON pedidos;

CREATE TRIGGER trg_actualizar_stock
AFTER UPDATE OF estado ON pedidos -- Solo se activa si cambia la columna 'estado'
FOR EACH ROW                      -- Se ejecuta por cada pedido modificado
EXECUTE FUNCTION gestionar_cambio_estado_pedido();