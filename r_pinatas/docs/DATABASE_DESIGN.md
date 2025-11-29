# Arquitectura de Base de Datos - R Piñatas
**Tecnología:** Google Cloud Firestore (NoSQL)

Este documento describe la estructura de colecciones y documentos para la persistencia de datos del proyecto.

## 1. Colección: `users`
Almacena la información de perfil y roles de los usuarios.

**ID del Documento:** `uid` (Generado por Firebase Auth)

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `email` | String | Correo electrónico del usuario. |
| `fullName` | String | Nombre completo del cliente o admin. |
| `role` | String | Puede ser `'client'` o `'admin'`. Campo crítico para seguridad. |
| `createdAt` | Timestamp | Fecha de registro. |

## 2. Colección: `categories`
Categorías para filtrar productos (ej. Piñatas, Dulces).

**ID del Documento:** Auto-generado

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `name` | String | Nombre de la categoría (ej. "Superhéroes"). |
| `imageUrl` | String | URL de la imagen representativa. |
| `isActive` | Boolean | Si la categoría debe mostrarse en la app. |

## 3. Colección: `products`
Inventario principal del negocio.

**ID del Documento:** Auto-generado

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `name` | String | Nombre del producto. |
| `description` | String | Detalles del producto. |
| `price` | Double | Precio unitario. |
| `stock` | Integer | Cantidad disponible actual. |
| `categoryId` | String | ID de la categoría a la que pertenece. |
| `images` | List<String> | URLs de las imágenes (la primera es la principal). |
| `isFeatured` | Boolean | Si aparece en destacados/home. |

## 4. Colección: `orders`
Registro de ventas y pedidos.

**ID del Documento:** Auto-generado

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `userId` | String | ID del usuario que compró. |
| `userEmail` | String | Correo de contacto para este pedido. |
| `totalAmount` | Double | Monto total de la compra. |
| `status` | String | Estados: `'pending'`, `'processing'`, `'delivered'`. |
| `createdAt` | Timestamp | Fecha del pedido. |
| `items` | Array | Lista de items comprados. |