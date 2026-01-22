# pocket

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Nuevas vistas (frontend solo)

Se añadieron pantallas únicamente de UI basadas en el PDF proporcionado. No hay lógica de backend; el botón "Iniciar sesión" navega a la pantalla principal (`Home`) sin autenticación.

Archivos añadidos en `lib/screens/`:

- `login_screen.dart` — Pantalla de inicio de sesión (navega a `/home`).
- `register_screen.dart` — Formulario de registro (mock).
- `home_screen.dart` — Contenedor principal con BottomNavigation.
- `recipes_list_screen.dart` — Lista de recetas (mock) que navega a detalle.
- `recipe_detail_screen.dart` — Detalle de receta (mock).
- `profile_screen.dart` — Perfil de usuario (mock) con botón de cerrar sesión.

Probar localmente:

1. Abre una terminal en la carpeta del proyecto.
2. Ejecuta `flutter pub get` si no has descargado dependencias.
3. Ejecuta `flutter run` y la app iniciará en la pantalla de login.

Navegación relevante:

- `/login` → `LoginScreen` (inicial)
- `/register` → `RegisterScreen`
- `/home` → `HomeScreen`
- `/recipe` → `RecipeDetailScreen` (usa `arguments` para título/id)
