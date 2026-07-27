# PocketControl - Pantalla de Inicio de Sesión

Esta primera versión de PocketControl implementa la pantalla de inicio de sesión y cierre de sesión para una app de finanzas personales.

## Propósito

La pantalla `LoginScreen` permite que el usuario ingrese sus credenciales, restaura automáticamente la sesión si ya estaba activa y muestra un saludo personalizado cuando la app se abre de nuevo.

## Flujo de inicio y cierre de sesión

1. Al abrir la app, la pantalla muestra un indicador de carga mientras se leen las preferencias guardadas.
2. Si `sesionActiva` es `true`, la interfaz muestra `Bienvenido, [nombre]` y el botón `Cerrar sesión`.
3. Si no hay sesión activa, se muestra un formulario con dos campos: `Nombre` y `Contraseña`.
4. Antes de iniciar sesión, la pantalla valida que ambos campos tengan contenido.
5. Si la validación es correcta, se guardan el nombre, la contraseña y el estado de sesión activa.
6. Al cerrar sesión, se eliminan todos los datos guardados y la pantalla vuelve al formulario vacío.

## Persistencia con SharedPreferences

La persistencia está separada en `PreferencesService` para que la UI no acceda directamente a `SharedPreferences`.

Se guardan estos valores:

- `nombre`: nombre del usuario.
- `contrasena`: contraseña ingresada.
- `sesionActiva`: bandera booleana que indica si la sesión debe restaurarse automáticamente.

La sesión se restaura cuando la app arranca y encuentra `sesionActiva == true`. En ese caso, `LoginScreen` consulta el nombre y muestra la vista de bienvenida en lugar del formulario.

## Archivos creados

- `lib/services/preferences_service.dart`: contiene la lógica de lectura, guardado y borrado de preferencias.
- `lib/screens/login_screen.dart`: contiene la pantalla de login como `StatefulWidget`, la validación del formulario, la restauración automática y el cierre de sesión.
- `lib/main.dart`: punto de entrada mínimo de la aplicación con `MaterialApp`, Material 3 y `LoginScreen` como pantalla inicial.

## Cómo probar la pantalla

1. Ejecuta la app con `flutter run`.
2. Ingresa un nombre y una contraseña.
3. Presiona `Iniciar sesión`.
4. Cierra y vuelve a abrir la app para verificar que la sesión se restaura automáticamente.
5. Presiona `Cerrar sesión` para confirmar que los datos se borran y el formulario vuelve a aparecer vacío.

## Notas de diseño

- La interfaz usa Material 3.
- Los campos tienen bordes redondeados y estilo sobrio.
- El botón principal ocupa todo el ancho disponible para mejorar la usabilidad en móvil.