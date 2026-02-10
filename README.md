# Proyecto E-commerce: Base de Datos Relacional (PostgreSQL)

Este proyecto es una simulación educativa de una base de datos para una tienda en línea (E-commerce). Está diseñado para aprender cómo funcionan las bases de datos profesionales, incluyendo el manejo de inventario, carritos de compra y seguridad en las transacciones.

## 1. Descripción General de la Base de Datos

El diseño separa la información en tablas lógicas para mantener el orden y la eficiencia.

### Características Principales:
* **Inventario Separado:** Los productos (nombre, descripción) están en una tabla y la cantidad disponible en otra. Esto hace que la tienda sea más rápida cuando muchos usuarios compran a la vez.
* **Reglas de Seguridad:** La base de datos impide errores comunes, como precios negativos o borrar un usuario que tiene compras pendientes.
* **Automatización (Triggers):** El sistema descuenta el stock automáticamente cuando se paga un pedido. Si se cancela, devuelve el stock.
* **Historial de Precios:** Guardamos el precio al que se vendió el producto. Si el precio sube mañana, el registro de la venta antigua no cambia.

## 2. Estructura del Proyecto y Orden de Ejecución

Para probar el proyecto, ejecuta los archivos SQL en este orden:

### 1. `schema.sql` (DDL - Estructura)
* **Qué hace:** Crea el "esqueleto" de la base de datos (tablas, reglas y conexiones).
* **Nota:** Borra cualquier dato anterior para empezar limpio.

### 2. `seed.sql` (DML - Carga de Datos)
* **Qué hace:** Llena las tablas con datos de prueba (Usuarios falsos, productos, stock inicial).
* **Objetivo:** Tener información para poder hacer consultas y pruebas.

### 3. `transaction.sql` (Pruebas Transaccionales)
* **Qué hace:** Simula una compra completa paso a paso.
* **Objetivo:** Probar que el sistema descuenta el stock correctamente y maneja el carrito de compras.

### 4. `queries.sql` (Reportes)
* **Qué hace:** Muestra ejemplos de cómo pedirle información a la base de datos (Reportes de ventas, productos más vendidos, etc.).

---

## 3. Evidencia de Ejecución (Resultados Esperados)

Estos son los resultados que deberías ver si todo funciona bien.

### A. Ejecución del Trigger y Control de Stock (Simulación)
Al ejecutar `transaction.sql`, verás mensajes confirmando la compra.

**Salida en consola (PostgreSQL Messages):**
```text
NOTICE:  [PASO 3] Procesando pago (Cambio de estado a PAGADO)...
NOTICE:  ... Esperando ejecución de Triggers de inventario ...
NOTICE:  ALERTA STOCK: Producto ID 22 queda con 2 unidades.
NOTICE:  [OK] Producto B: Stock bajó de 3 a 2.

```

*Interpretación: El sistema detectó que al vender el producto ID 15, el stock bajó del umbral seguro (5) y emitió una alerta automática, pero permitió la venta.*

### B. Consulta de Productos y Stock Actual

Esta consulta une el catálogo con la tabla de inventario normalizada.

**Query:**

```sql
SELECT p.nombre, p.precio, s.cantidad as stock, c.nombre as categoria 
FROM productos p 
JOIN stock_de_productos s ON p.id = s.producto_id 
JOIN categorias c ON p.categoria_id = c.id 
WHERE s.cantidad <= 5;

```

**Resultado:**

| nombre                  | precio  | stock | categoria      |
| :---------------------- | :------ | :---- | :------------- |
| NVIDIA RTX 4090         | 169900.00 | 2     | Componentes PC |
| Samsung Odyssey G9      | 119900.00 | 3     | Monitores      |
| Dell UltraSharp 32"     | 75000.00  | 4     | Monitores      |
| Dell XPS 15             | 210000.00 | 5     | Laptops        |

### C. Reporte de "Best Sellers" (Lo más vendido)

Muestra los productos con mayor salida (solo de pedidos pagados).

**Query:**

```sql
SELECT p.nombre, SUM(dp.cantidad) as vendidos 
FROM detalle_pedidos dp 
JOIN pedidos pe ON dp.pedido_id = pe.id 
JOIN productos p ON dp.producto_id = p.id 
WHERE pe.estado = 'pagado' 
GROUP BY p.nombre 
ORDER BY vendidos DESC LIMIT 3;

```

**Resultado:**

| nombre            | vendidos |
| :---------------- | :------- |
| Lenovo Legion 5         | 1        |
| Logitech MX Master 3S   | 1        |
| AMD Ryzen 7 7800X3D     | 1        |

---

## Requisitos Técnicos

* **Motor:** PostgreSQL 12 o superior.
* **Cliente:** psql, pgAdmin 4.
---
Hecho con ❤️ por GatoPobre
