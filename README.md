# XaFit

XaFit es una app de entrenamiento personal desarrollada en **Flutter** como proyecto de portfolio, con un enfoque **mobile-first**, **offline-first** y centrado en el flujo de **entrenamiento libre**.

La idea principal de la app no gira en torno a rutinas cerradas, sino en permitir registrar entrenamientos reales de forma rápida, flexible y útil para el día a día.  
Actualmente la prioridad del proyecto es **Android**, con intención de dar soporte a **iPhone/iOS** más adelante. La versión web se usa como apoyo visual y de desarrollo, pero no es el objetivo principal del producto.

---

## Objetivo del proyecto

Construir una app de fitness sólida, moderna y bien estructurada, pensada como proyecto personal y de portfolio, priorizando:

- una buena experiencia de uso en móvil
- persistencia local robusta
- arquitectura mantenible
- base preparada para evolucionar a futuro con sincronización en la nube

---

## Estado actual

XaFit ya cuenta con una base funcional bastante completa:

- Dashboard/Home con resumen visual del progreso
- Entrenamiento libre con guardado real de sesiones
- Historial de entrenamientos
- Biblioteca de ejercicios
- Ejercicios personalizados
- Seguimiento corporal
- Recordatorio semanal
- Exportación e importación de backup
- Guardado automático de borrador de entrenamiento
- Persistencia principal con **Drift**

La app está pensada primero para **uso real offline**, dejando la sincronización como una futura evolución del proyecto.

---

## Funcionalidades principales

### Inicio / Dashboard
- Hero principal con acceso rápido al entrenamiento
- Métricas clave:
  - sesiones totales
  - entrenamientos de la semana
  - volumen semanal
  - peso actual
- Resumen semanal más visual
- Último entrenamiento
- Actividad reciente
- Objetivo actual
- Banner de **“Entreno en curso”** si existe un borrador guardado

### Entrenamiento libre
- Añadir ejercicios
- Añadir, editar y borrar series
- Duplicar última serie
- Referencias de:
  - **Última vez**
  - **PR**
- Reordenar ejercicios
- Confirmación al salir sin guardar
- Guardado automático de borrador local
- Recuperación automática de entrenamiento si la app se cierra inesperadamente
- Eliminación del borrador al finalizar o descartar el entreno

### Historial
- Lista de sesiones guardadas
- Filtros por etiqueta y fecha
- Pantalla de detalle de sesión

### Biblioteca
- Ejercicios por grupo muscular
- Buscador
- Filtros por tags
- Soporte para ejercicios personalizados

### Ejercicios personalizados
- Crear ejercicios
- Editar ejercicios
- Eliminar ejercicios

### Progreso corporal
- Perfil básico
- Registros corporales
- Gráfica por métrica
- Historial de registros
- CRUD completo de entradas corporales
- Recordatorio semanal configurable
- Exportación e importación de backup

### Recordatorio semanal
- Activación y desactivación desde la app
- Configuración de hora
- Persistencia del estado del recordatorio
- Preparado para notificaciones en móvil

### Backup
- Exportación de datos a JSON
- Importación de backup
- Incluye:
  - perfil
  - progreso corporal
  - sesiones
  - ejercicios personalizados

---

## Enfoque de producto

XaFit está diseñada con una idea clara:

- **mobile-first**
- **offline-first**
- experiencia de uso rápida
- evitar depender de nube desde el inicio
- dejar una base fuerte antes de añadir sync

La app no busca obligar al usuario a seguir planes cerrados, sino ayudarle a registrar y revisar sus entrenamientos de forma natural.

---

## Stack tecnológico

- **Flutter**
- **Dart**
- **Drift** como persistencia principal en móvil/escritorio
- **shared_preferences** como fallback en web y para estados temporales
- **flutter_local_notifications** para recordatorios
- **file_picker** para importación/exportación
- **share_plus** para compartir backups
- **build_runner** para generación de código de Drift

---

## Arquitectura y persistencia

La app usa una arquitectura con repositorios desacoplados y servicios específicos.

### Repositorios
- `WorkoutRepository`
- `SharedPrefsWorkoutRepository`
- `DriftWorkoutRepository`

- `BodyProfileRepository`
- `SharedPrefsBodyProfileRepository`
- `DriftBodyProfileRepository`

- `BodyProgressRepository`
- `SharedPrefsBodyProgressRepository`
- `DriftBodyProgressRepository`

- `CustomExerciseRepository`
- `SharedPrefsCustomExerciseRepository`
- `DriftCustomExerciseRepository`

### Servicios
- `DashboardService`
- `ProgressService`
- `DataMigrationService`
- `BackupService`
- `WorkoutDraftService`

### Inicialización
- `main.dart` ejecuta la migración de datos antes de `runApp`
- `DataMigrationService` migra datos legacy a Drift en entornos no web

---

## Base de datos

Persistencia principal con **Drift**.

### Tablas actuales
- `WorkoutSessions`
- `WorkoutExercises`
- `WorkoutSets`
- `ProfileRecords`
- `BodyProgressRecords`
- `CustomExercises`

### Versión de esquema
- `schemaVersion: 3`

### Importante
Si se modifica `app_database.dart`, hay que regenerar los archivos con:

    flutter pub run build_runner build --delete-conflicting-outputs

---

## Estado de plataforma

### Android
Es la plataforma principal en este momento y donde está centrado el desarrollo.

### iOS
Está previsto como siguiente fase del proyecto.  
La intención es preparar XaFit para uso real en iPhone, pero el foco actual ha sido primero consolidar la base funcional y offline en Android.

### Web
Se usa como apoyo visual y para desarrollo rápido, pero no es la plataforma objetivo del producto.

---

## Decisiones técnicas tomadas

- Prioridad real: **Android / iPhone**, no web
- Mantener la web solo como apoyo visual
- **Drift** como base principal de persistencia en móvil
- **Firebase no es la opción preferida**
- Si en el futuro se añade sync/cloud, la opción más probable es **Supabase**
- Antes de añadir sincronización, el objetivo es dejar XaFit robusta como app **offline-first**

---

## Problemas ya resueltos durante el desarrollo

Algunos puntos técnicos importantes que ya se han resuelto:

- Configuración Android y emulador funcionando
- `flutter_local_notifications` arreglado con desugaring
- Persistencia Drift validada en Android
- Crash al guardar ejercicios personalizados solucionado moviendo diálogos a widgets propios
- Crash al guardar series solucionado rehaciendo el bottom sheet de series
- Textos corruptos por codificación corregidos
- Overflow visual en cards de progreso corregido
- Errores de imports ambiguos con `WorkoutDraft` / `WorkoutDraftService` corregidos
- Sistema de borrador de entrenamiento saneado
- `flutter analyze` limpio
- Recordatorio semanal conectado y funcionando

---

## Instalación

### Requisitos
- Flutter SDK
- Dart SDK
- Android Studio o VS Code
- Dispositivo Android o emulador para pruebas principales

### Clonar el proyecto

    git clone https://github.com/AsdDev73/xafit.git
    cd xafit

### Instalar dependencias

    flutter pub get

### Generar código de Drift si hace falta

    flutter pub run build_runner build --delete-conflicting-outputs

### Ejecutar la app

    flutter run

### Ejecutar en Android

    flutter run -d android

### Ejecutar en Chrome como apoyo visual

    flutter run -d chrome

---

## Estructura general del proyecto

    lib/
    ├── data/
    ├── db/
    ├── models/
    ├── repositories/
    ├── screens/
    ├── services/
    ├── widgets/
    └── main.dart

---

## Repositorio

GitHub: [https://github.com/AsdDev73/xafit](https://github.com/AsdDev73/xafit)

---

## Capturas

Pendiente de añadir capturas reales de la app:

- Home / Dashboard
- Entrenamiento libre
- Historial
- Biblioteca
- Progreso corporal
- Recordatorio semanal
- Backup

---

## Roadmap

### Próximos pasos
- Mejoras visuales adicionales en Home y flujo general
- Mejoras de métricas y estadísticas
- Mejoras de UX en historial y progreso
- Preparación real para iOS
- Pulido de onboarding / empty states
- Capturas y presentación visual para portfolio

### Futuro
- Sincronización en la nube
- Posible integración con Supabase
- Más analítica y comparativas de progreso
- Mejoras avanzadas de rendimiento y experiencia de usuario

---

## Filosofía del proyecto

XaFit no pretende ser solo una demo técnica.  
La idea es construir una app que se sienta como un producto real: útil, rápida, clara y bien estructurada.

Por eso el proyecto prioriza:
- usabilidad real
- arquitectura limpia
- persistencia estable
- evolución progresiva sin romper lo que ya funciona

---

## Autor

Desarrollado por **Antonio** como proyecto personal y de portfolio.

---

## Licencia

Este proyecto se publica con fines de aprendizaje, portfolio y evolución personal como desarrollador.
