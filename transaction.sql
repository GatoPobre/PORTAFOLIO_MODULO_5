-- ==============================================================================
-- ARCHIVO: transaction.sql
-- DESCRIPCIÓN: Simulación de una Compra Completa.
-- MOTIVO: Verificar que el sistema funciona correctamente (crear usuario, carrito, pagar y descontar stock).
-- AUTOR: Marcos Araya Morales
-- APOYO: Inteligencia Artificial (Gemini 3 de Google)
-- ==============================================================================

--  SIMULACION DE COMPRA COMPLETA (TRANSACCIÓN ATÓMICA) USANDO DO $$ ... END $$ , CON MANEJO DE ERRORES Y VALIDACIONES FINALES.
-- DO $$ ... END $$: Bloque de código temporal.
-- Nos permite ejecutar una serie de pasos complejos (variables, lógica) sin necesidad de guardar una función permanente en la base de datos.
-- Es ideal para simulaciones, pruebas o scripts de mantenimiento que no queremos que queden como parte del esquema de la base de datos.
-- Tiene su propio contexto de transacción, así que si algo falla, podemos hacer ROLLBACK para deshacer todos los cambios realizados dentro de este bloque.
DO $$
DECLARE
-- DECLARE es la sección donde definimos variables para usar dentro de este bloque de código.
    v_cliente_id INT; -- ID del usuario cliente creado para esta simulación
    v_pedido_id INT;  -- ID del pedido que se creará y procesará
    v_prod_normal_id INT; -- ID del producto con stock normal (abundante)
    v_prod_critico_id INT; -- ID del producto con stock crítico (escaso)
    
    -- Variables para validación final
    v_stock_final_normal INT; -- Stock final del producto normal después de la compra
    v_stock_final_critico INT; -- Stock final del producto crítico después de la compra
BEGIN
-- El bloque BEGIN...EXCEPTION...END es la estructura principal de esta transacción. Aquí va toda la lógica que queremos ejecutar de forma atómica.
    RAISE NOTICE '';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '   INICIO DE SIMULACIÓN DE COMPRA (TRANSACCIÓN ATÓMICA)';
    RAISE NOTICE '==================================================================';

    -- ------------------------------------------------------------------
    -- PASO 1: PREPARACIÓN DE DATOS (Setup)
    -- Creamos un usuario y productos específicos para no ensuciar los datos base.
    -- ------------------------------------------------------------------
    RAISE NOTICE '[PASO 1] Creando entorno de prueba (Usuario y Productos)...';
    
    -- 1.1 Crear Cliente (Email dinámico para evitar errores si se ejecuta varias veces)
    -- RETURNING id INTO: Al crear el usuario, obtenemos su nuevo ID y lo guardamos en la variable 'v_cliente_id'.
    INSERT INTO usuarios (nombre, email, hash_password, rol) 
    -- El email se genera con un número aleatorio para evitar conflictos si se ejecuta varias veces.
    -- floor(random()*10000)::text genera un número aleatorio entre 0 y 9999, que se concatena al email base.
    -- las || son para concatenar texto en SQL.
    VALUES ('Cliente Test', 'test_user_' || floor(random()*10000)::text || '@simulation.com', 'hash123', 'cliente') 
    RETURNING id INTO v_cliente_id;

    -- 1.2 Crear Producto A (Stock Abundante)
    INSERT INTO productos (nombre, descripcion, precio, categoria_id) 
    -- No asignamos categoría (NULL) para simplificar, ya que el trigger no depende de ella.
    VALUES ('Producto Test A (Abundante)', 'Stock inicial 100', 5000, NULL) 
    RETURNING id INTO v_prod_normal_id;

    INSERT INTO stock_de_productos (producto_id, cantidad, stock_minimo) 
    VALUES (v_prod_normal_id, 100, 10);

    -- 1.3 Crear Producto B (Stock Crítico)
    -- Stock inicial 3, Mínimo 5. Al comprar 1, bajará a 2. Debería saltar alerta.
    INSERT INTO productos (nombre, descripcion, precio, categoria_id) 
    VALUES ('Producto Test B (Escaso)', 'Stock inicial 3', 100000, NULL) 
    RETURNING id INTO v_prod_critico_id;

    INSERT INTO stock_de_productos (producto_id, cantidad, stock_minimo) 
    VALUES (v_prod_critico_id, 3, 5);

    RAISE NOTICE '   -> Cliente ID: % creado.', v_cliente_id;
    RAISE NOTICE '   -> Producto A (ID %): Stock 100.', v_prod_normal_id;
    RAISE NOTICE '   -> Producto B (ID %): Stock 3 (Crítico).', v_prod_critico_id;

    -- ------------------------------------------------------------------
    -- PASO 2: CREACIÓN DEL PEDIDO (Carrito)
    -- Estado inicial 'ingresado'. El stock NO debe moverse aún.
    -- ------------------------------------------------------------------
    RAISE NOTICE '[PASO 2] Creando pedido en estado INGRESADO...';
    
    INSERT INTO pedidos (usuario_id, estado) 
    VALUES (v_cliente_id, 'ingresado') 
    RETURNING id INTO v_pedido_id;

    -- Agregamos items al carrito
    -- Simulamos agregar 2 unidades de A y 1 unidad de B
    INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
    VALUES 
        (v_pedido_id, v_prod_normal_id, 2, 5000),
        (v_pedido_id, v_prod_critico_id, 1, 100000);

    -- SIMULACIÓN DE "CARRITO INTELIGENTE" (UPSERT):
    -- El usuario agrega 1 unidad MÁS del mismo producto.
    -- ON CONFLICT: Si el producto ya está en el carrito, en lugar de dar error, sumamos la cantidad existente.
    INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
    VALUES (v_pedido_id, v_prod_normal_id, 1, 5000)
    ON CONFLICT (pedido_id, producto_id) 
    -- EXCLUDED.cantidad se refiere a la cantidad que intentamos insertar (1 unidad adicional).
    DO UPDATE SET cantidad = detalle_pedidos.cantidad + EXCLUDED.cantidad;

    RAISE NOTICE '   -> Pedido #% actualizado. Producto A ahora tiene 3 unidades (2+1).', v_pedido_id;

    -- ------------------------------------------------------------------
    -- PASO 3: PROCESAR PAGO (Trigger Action)
    -- Cambiamos estado a 'pagado'. Aquí debe dispararse el trigger.
    -- ------------------------------------------------------------------
    RAISE NOTICE '[PASO 3] Procesando pago (Cambio de estado a PAGADO)...';
    RAISE NOTICE '   ... Esperando ejecución de Triggers de inventario ...';

    UPDATE pedidos 
    SET estado = 'pagado' 
    WHERE id = v_pedido_id;

    -- ------------------------------------------------------------------
    -- PASO 4: VERIFICACIÓN DE RESULTADOS
    -- Consultamos el stock final para asegurar que se descontó.
    -- ------------------------------------------------------------------
    RAISE NOTICE '[PASO 4] Verificando actualización de stock...';

    SELECT cantidad INTO v_stock_final_normal FROM stock_de_productos WHERE producto_id = v_prod_normal_id;
    SELECT cantidad INTO v_stock_final_critico FROM stock_de_productos WHERE producto_id = v_prod_critico_id;

    -- Validaciones
    IF v_stock_final_normal = 97 THEN
        RAISE NOTICE '   [OK] Producto A: Stock bajó de 100 a 97 (3 unidades vendidas).';
    ELSE
        RAISE EXCEPTION '   [ERROR] Producto A: Stock incorrecto (%). Se esperaban 97.', v_stock_final_normal;
    END IF;

    IF v_stock_final_critico = 2 THEN
        RAISE NOTICE '   [OK] Producto B: Stock bajó de 3 a 2.';
    ELSE
        RAISE EXCEPTION '   [ERROR] Producto B: Stock incorrecto (%)', v_stock_final_critico;
    END IF;

    RAISE NOTICE '==================================================================';
    RAISE NOTICE '   SIMULACIÓN COMPLETADA CON ÉXITO';
    RAISE NOTICE '==================================================================';

EXCEPTION
    -- MANEJO DE ERRORES:
    -- Si algo falla en cualquier paso, llegamos aquí.
    WHEN OTHERS THEN
        RAISE NOTICE '!!! ERROR EN LA TRANSACCIÓN: % !!!', SQLERRM;
        ROLLBACK;
        -- El ROLLBACK deshace cualquier cambio hecho durante esta transacción, asegurando que la base de datos vuelva al estado inicial antes de la simulación.
END $$;

--==================================================================================	
--  SIMULACION DE COMPRA COMPLETA (USANDO WITH QUERIES PARA HACER PRUEBAS RÁPIDAS.
--  WITH QUERIES (CTEs): Nos permite encadenar varias consultas y usar los resultados de unas en otras, ideal para pruebas rápidas sin necesidad de un bloque DO.
--  Es menos formal que el bloque DO, pero útil para validar pasos específicos de forma rápida.
--  Tambien  mantiene la atomicidad dentro de su ejecución, así que si algo falla, no se aplicará ningún cambio.
--===================================================================================
WITH 
    -- 1. Creamos el cliente
    nuevo_cliente AS (
        INSERT INTO usuarios (nombre, email, hash_password, rol) 
        VALUES ('Cliente Test', 'test_user_' || floor(random()*10000)::text || '@simulation.com', 'hash123', 'cliente') 
        RETURNING id
    ),

    -- 2. Creamos el pedido (leemos el ID del paso anterior)
    nuevo_pedido AS (
        INSERT INTO pedidos (usuario_id, estado) 
        SELECT id, 'ingresado' FROM nuevo_cliente
        RETURNING id as id_pedido_generado
    ),

    -- 3. Agregamos el detalle (leemos el ID del paso anterior)
    detalle_agregado AS (
        INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
        SELECT id_pedido_generado, 1, 2, 5 FROM nuevo_pedido -- cambiar la cantidad a 200 para lanzar error
        -- IMPORTANTE: Retornamos también producto_id y cantidad para usarlos en el siguiente paso
        RETURNING pedido_id, producto_id, cantidad
    ),

    -- 4. Actualizamos el Stock del Producto (Depende de detalle_agregado)
    actualizar_stock AS (
        UPDATE stock_de_productos
        SET cantidad = cantidad - (SELECT cantidad FROM detalle_agregado)
        WHERE producto_id = (SELECT producto_id FROM detalle_agregado)
		RETURNING 1 as mensaje
    )
SELECT * from actualizar_stock;
-- Si algo falla en cualquiera de los pasos anteriores, no se aplicará ningún cambio a la base de datos,
-- manteniendo la integridad de los datos.
-- si todo sale bien, veremos el mensaje de confirmación del último paso (actualización de stock).
-- pero debemos actualizar el estado del pedido a 'pagado' manualmente para simular el proceso completo,
-- los CTEs no permiten ejecutar un UPDATE que dependa de su resultado dentro del mismo bloque,
-- así que lo hacemos después de la consulta.
BEGIN;
UPDATE pedidos 
        SET estado = 'pagado' 
        WHERE id = (SELECT MAX(id) FROM pedidos);-- actualizamos el pedido recién creado (el de ID más alto)
COMMIT;
SELECT * FROM  pedidos ORDER BY id DESC LIMIT 1;

--=====================================================
--  SIMULACION DE COMPRA COMPLETA (DENTRO DE UNA TRANSACCIÓN MANUAL)
-- podemos ejecutar cada paso manualmente dentro de una transacción. Esto nos permite verificar resultados intermedios antes de continuar.
-- CON ESTA IMPLEMENTACION SE SATISFACE EL REQUISITO DE REALIZAR LA SIMULACIÓN PASO A PASO, VERIFICANDO RESULTADOS ANTES DE CONTINUAR AL SIGUIENTE PASO.
-- SI EL TRIGGER NO FUE CREADO, DEBEMOS DESCONTAR EL STOCK MANUALMENTE EN CADA PASO PARA SIMULAR EL EFECTO DEL TRIGGER.
----===================================================================================
BEGIN;
INSERT INTO usuarios (nombre, email, hash_password, rol) 
        VALUES ('Cliente Test', 'test_user_' || floor(random()*10000)::text || '@simulation.com', 'hash123', 'cliente') ;
INSERT INTO pedidos (usuario_id, estado) 
-- currval(pg_get_serial_sequence('usuarios', 'id')): Esta función obtiene el último ID generado para la tabla 'usuarios', 
--lo que nos permite asociar el pedido al cliente recién creado.
        VALUES (currval(pg_get_serial_sequence('usuarios', 'id')), 'ingresado') ;
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio_unitario)
-- Aquí también usamos currval para obtener el ID del pedido recién creado y asociar el detalle correctamente.
        VALUES (currval(pg_get_serial_sequence('pedidos', 'id')), 1, 2, 5000);   
-- cambiamos el estado a 'pagado' para simular el proceso de pago.
-- sino se ha creado el trigger, debemos descontar el stock manualmente aquí para simular su efecto.
UPDATE pedidos 
    SET estado = 'pagado' 
    WHERE id = (currval(pg_get_serial_sequence('pedidos', 'id'))); -- actualizamos el pedido recién creado 
-- realizamos el descuento manual del stock
UPDATE stock_de_productos 
    SET cantidad = cantidad - 2 -- descontamos 2 para que pase la compra, usar 100 para que falle
    WHERE producto_id = 1;     
COMMIT;
-- Si algo falla antes del COMMIT, podemos hacer ROLLBACK para deshacer los cambios. Esto es útil para pruebas paso a paso.
-- ROLLBACK; -- Descomenta esto si quieres deshacer los cambios