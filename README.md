# PocketControl - Login y Menú Principal

PocketControl ahora incluye el flujo de acceso y la segunda pantalla principal del producto: el Dashboard financiero.

## Pantalla 1: Login

La pantalla `LoginScreen` sigue siendo el punto de entrada de la app. Su responsabilidad es validar credenciales simples, guardar la sesión y redirigir al menú principal cuando el acceso ya fue confirmado o cuando la sesión activa se detecta al abrir la app.

## Pantalla 2: Dashboard

La pantalla `DashboardScreen` es el menú principal de PocketControl. Su propósito es mostrar un resumen rápido del estado financiero del usuario y ofrecer accesos directos a las funciones más importantes de la app.

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
2. Se eliminan los datos guardados del usuario, la sesión y los totales financieros.
3. La navegación regresa a `LoginScreen` usando `Navigator.pushReplacement`.

## Persistencia con SharedPreferences

La persistencia está separada en `PreferencesService` para mantener la lógica de datos fuera de la UI.

Se guardan estos valores:

- `nombre`: nombre del usuario.
- `contrasena`: contraseña ingresada.
- `sesionActiva`: bandera booleana que indica si la sesión debe restaurarse automáticamente.
- `totalIngresos`: total acumulado de ingresos, tipo `double`.
- `totalGastos`: total acumulado de gastos, tipo `double`.

Si `totalIngresos` o `totalGastos` no existen todavía, se usan por defecto como `0.0`.

## Archivos nuevos o modificados

- `lib/screens/dashboard_screen.dart`: nueva pantalla principal con tarjetas, accesos rápidos y cierre de sesión.
- `lib/screens/login_screen.dart`: ahora redirige al Dashboard cuando la sesión ya está activa o cuando el login se completa correctamente.
- `lib/services/preferences_service.dart`: agrega lectura y guardado de ingresos y gastos acumulados.

## Cómo probar el flujo

1. Ejecuta la app con `flutter run`.
2. Ingresa un nombre y una contraseña en la pantalla de login.
3. Verifica que al iniciar sesión se abre el Dashboard.
4. Confirma que los valores de saldo, ingresos y gastos se muestran con formato monetario.
5. Prueba los accesos rápidos y luego cierra sesión desde el ícono del `AppBar`.

## Notas de diseño

- La interfaz usa Material 3.
- Las tarjetas usan esquinas redondeadas y jerarquía visual clara.
- El Dashboard prioriza una lectura rápida del estado financiero con un layout limpio tipo app de finanzas.