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

```bash
flutter pub run build_runner build --delete-conflicting-outputs