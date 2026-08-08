# PocketControl - Login, Dashboard y rutas nombradas

PocketControl ahora incluye el flujo de acceso, el Dashboard financiero, navegación con rutas nombradas y persistencia real de movimientos.

## Cambios recientes

### Sistema de rutas nombradas

La navegación ya no usa `MaterialPageRoute` directo. Todas las rutas viven en `lib/routes/app_routes.dart` dentro de `AppRoutes`, y `MaterialApp` las registra en un solo lugar.

Esto ayuda a mantener la navegación consistente, evita literales sueltos y permite volver con `Navigator.pop(context)` o reemplazar pantallas con `Navigator.pushReplacementNamed(...)` cuando corresponde.

### Registro real de usuarios

La pantalla de Login ahora permite crear una cuenta real con nombre, contraseña y confirmación. El registro valida campos vacíos, longitud mínima de contraseña y coincidencia entre contraseña y confirmación.

Al registrarse, el usuario se guarda en `SharedPreferences` y luego puede iniciar sesión con esas credenciales. Si todavía no existe ningún usuario, la app muestra un mensaje claro para crear una cuenta antes de intentar ingresar.

### Sincronización entre Dashboard, Ingreso y Gasto

Las pantallas de registrar ingreso y registrar gasto guardan el movimiento, actualizan los totales persistidos y luego hacen `Navigator.pop(context)`.

En el Dashboard, cada acceso rápido espera el regreso de la pantalla abierta y recarga los datos desde `PreferencesService`, así que el saldo, los ingresos y los gastos se refrescan sin cerrar la app.

### Historial de movimientos

Los movimientos se guardan como una lista JSON en `SharedPreferences` con tipo, monto, categoría, fecha y descripción opcional.

La pantalla de historial lee esa lista con `PreferencesService.obtenerMovimientos()` y la presenta para consulta del usuario.

## Pantalla 1: Login

La pantalla `LoginScreen` sigue siendo el punto de entrada de la app. Su responsabilidad es validar credenciales simples, guardar la sesión y redirigir al menú principal cuando el acceso ya fue confirmado o cuando la sesión activa se detecta al abrir la app.

## Pantalla 2: Dashboard

La pantalla `DashboardScreen` es el menú principal de PocketControl. Su propósito es mostrar un resumen rápido del estado financiero del usuario y ofrecer accesos directos a las funciones más importantes de la app.

Desde el `AppBar` también se puede abrir un selector pequeño de moneda para cambiar cómo se muestran el saldo, los ingresos y los gastos. La selección se guarda en `SharedPreferences` para conservar la preferencia entre sesiones.

### Datos que muestra

El Dashboard muestra tres tarjetas principales:

1. `Saldo actual`: se calcula como `totalIngresos - totalGastos`.
2. `Total de ingresos`: se lee desde SharedPreferences usando la clave `totalIngresos`.
3. `Total de gastos`: se lee desde SharedPreferences usando la clave `totalGastos`.

Todos los valores se obtienen desde `PreferencesService`, que centraliza la persistencia y evita que la UI acceda directamente a `SharedPreferences`.

### Navegación desde el Dashboard

La pantalla incluye cuatro accesos rápidos en forma de tarjetas:

1. `Registrar ingreso` navega a `IngresoScreen`.
2. `Registrar gasto` navega a `GastoScreen`.
3. `Historial` navega a `HistorialScreen`.
4. `Estadísticas` navega a `EstadisticasScreen`.

Si alguna de esas pantallas todavía no tiene contenido funcional, se muestran como `Scaffold` vacíos de marcador de posición con el título correspondiente.

### Cierre de sesión

El Dashboard incluye un botón de cerrar sesión en el `AppBar`. Al pulsarlo:

1. Se ejecuta `PreferencesService.cerrarSesion()`.
2. Se cierra la sesión activa sin borrar el usuario registrado.
3. La navegación regresa a `LoginScreen` usando `Navigator.pushReplacementNamed`.

## Persistencia con SharedPreferences

La persistencia está separada en `PreferencesService` para mantener la lógica de datos fuera de la UI.

Se guardan estos valores:

- `nombre`: nombre del usuario.
- `contrasena`: contraseña ingresada.
- `sesionActiva`: bandera booleana que indica si la sesión debe restaurarse automáticamente.
- `totalIngresos`: total acumulado de ingresos, tipo `double`.
- `totalGastos`: total acumulado de gastos, tipo `double`.
- `movimientos`: lista serializada en JSON con el historial de ingresos y gastos.

Si `totalIngresos` o `totalGastos` no existen todavía, se usan por defecto como `0.0`.

## Archivos nuevos o modificados

- `lib/routes/app_routes.dart`: centraliza todas las rutas nombradas de la app.
- `lib/screens/dashboard_screen.dart`: ahora navega con rutas nombradas y refresca los totales al volver de ingreso o gasto.
- `lib/screens/login_screen.dart`: incluye registro real de usuario y validación contra credenciales guardadas.
- `lib/services/preferences_service.dart`: agrega registro de usuario, lectura y guardado de ingresos, gastos e historial.
