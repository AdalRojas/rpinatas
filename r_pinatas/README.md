# 🪅 R Piñatas - E-Commerce & Gestión de Inventario

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Core-FFCA28?logo=firebase)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Academic-green)

> **Proyecto Final de Asignatura:** Programación de Aplicaciones Móviles y Backend.  
> **Instituto Tecnológico de Mérida** > **Profesor:** Rodrigo Fidel Gaxiola  
> **Alumno:** Encalada Rojas Jorge Adal  

## 📖 Descripción del Proyecto

**R Piñatas** es una solución integral de software (App Móvil + Panel Web) desarrollada en **Flutter** con backend en **Firebase**. Su objetivo es digitalizar la operación de un negocio local de piñatas.

El sistema maneja dos roles principales:
1.  **Cliente:** Puede explorar el catálogo, buscar productos, gestionar su carrito y realizar pedidos.
2.  **Administrador:** Cuenta con un Dashboard para ver métricas de venta, gestionar inventario (CRUD de productos y categorías) y cambiar el estatus de los pedidos.

---

## 🚀 Características Principales (Requerimientos)

### 👤 Módulo de Cliente
* **Autenticación:** Registro e Inicio de sesión con correo/contraseña (Firebase Auth).
* **Recuperación de Contraseña:** Envío de correo para restablecer credenciales.
* **Catálogo Dinámico:** Filtrado por categorías (Piñatas, Dulces, etc.) y barra de búsqueda en tiempo real.
* **Carrito de Compras:** Gestión de estado global con `Provider` para agregar/quitar ítems y calcular totales.
* **Gestión de Stock:** Validación visual ("AGOTADO") y lógica (bloqueo de compra) si el stock es insuficiente.
* **Pedidos:** Historial de "Mis Pedidos" con estatus en tiempo real.

### 🛠 Módulo de Administrador (Backoffice)
* **Dashboard:** Métricas clave (Ventas del día, Pedidos nuevos).
* **CRUD de Productos:** Crear, Editar y Eliminar productos con actualización de imágenes y stock.
* **Gestión de Categorías:** Sistema para crear nuevas etiquetas dinámicamente.
* **Control de Pedidos:** Visualización de detalles de órdenes y cambio de estatus (Pendiente -> Entregado).

---

## 🛠 Tecnologías y Librerías

El proyecto utiliza las siguientes dependencias clave:

| Dependencia | Uso |
| :--- | :--- |
| **flutter** | Framework UI principal. |
| **firebase_core** | Inicialización de servicios de Google. |
| **firebase_auth** | Gestión de usuarios y sesiones. |
| **cloud_firestore** | Base de datos NoSQL en tiempo real. |
| **provider** | Gestión de estado (State Management) para el Carrito. |
| **intl** | Formateo de fechas y monedas. |
| **flutter_credit_card** | Interfaz visual para la pasarela de pagos simulada. |
| **cached_network_image** | Optimización de carga de imágenes. |

---

## 📂 Arquitectura del Proyecto

El código sigue una estructura limpia separada por responsabilidades:

```text
lib/
├── models/         # Modelos de datos (Product, User)
├── providers/      # Lógica de negocio y Estado (CartProvider)
├── screens/        # Pantallas (UI)
│   ├── admin/      # Pantallas exclusivas del rol Admin
│   ├── client/     # Pantallas de la tienda y carrito
│   └── shared/     # Login, Splash, AuthWrapper
├── services/       # Comunicación con Firebase (AuthService)
├── widgets/        # Componentes reutilizables (CustomImage, Cards)
└── main.dart       # Punto de entrada e inyección de dependencias