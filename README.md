# XaFit

XaFit es una app de entrenamiento personal desarrollada con **Flutter** como proyecto de práctica y portfolio.

La idea principal de la app es poder registrar entrenamientos de forma rápida y cómoda, guardar series, pesos, repeticiones, descansos y llevar también un seguimiento del progreso corporal.

## Objetivo del proyecto

El objetivo de XaFit es crear una aplicación útil para el día a día en el gimnasio, con una interfaz clara, funcionalidades reales y una base sólida para seguir creciendo.

Además de ser una app personal, también está planteada como proyecto de portfolio para mostrar:
- desarrollo móvil con Flutter
- gestión de estado y navegación
- persistencia local de datos
- diseño de interfaz
- evolución progresiva de producto

---

## Funcionalidades actuales

### Entrenamiento
- Crear un **entrenamiento libre**
- Añadir ejercicios de distintos grupos musculares en una sola sesión
- Registrar series con:
  - peso
  - repeticiones
  - descanso automático
- Duplicar la última serie
- Editar y borrar series
- Guardar el entrenamiento en historial

### Biblioteca de ejercicios
- Catálogo de ejercicios por grupo muscular
- Búsqueda por nombre
- Filtro por tags
- Ejercicios predefinidos
- Posibilidad de añadir ejercicios personalizados

### Historial
- Guardado local de entrenamientos
- Consulta de sesiones anteriores
- Vista detallada de cada entrenamiento

### Rendimiento
- Referencia de **última vez realizada** por ejercicio
- **PR (personal record)** por ejercicio
- Mejor volumen de serie

### Progreso corporal
- Registro de peso corporal
- Registro opcional de medidas:
  - cintura
  - pecho
  - brazo
  - pierna
  - % grasa
- Perfil básico:
  - alias
  - altura
  - objetivo
  - peso objetivo
  - edad opcional
- Gráfica de evolución
- Historial de progreso corporal

### Dashboard principal
- Entrenos totales
- Entrenos de la semana
- Volumen semanal
- Peso actual
- Último entrenamiento

### Recordatorio semanal
- Configuración de recordatorio semanal para registrar el peso
- Preparado para móvil
- En web queda la configuración guardada, pero la notificación real se probará en dispositivo móvil

---

## Tecnologías usadas

- **Flutter**
- **Dart**
- **shared_preferences**
- **fl_chart**
- **flutter_local_notifications**
- **timezone**
- **flutter_timezone**

---

## Estado actual

Actualmente XaFit está en desarrollo activo.

La app ya cuenta con una base funcional sólida y sigue evolucionando con mejoras de:
- interfaz
- experiencia de usuario
- rendimiento
- nuevas estadísticas
- recordatorios
- versión móvil real en Android/iPhone

Por ahora el desarrollo se ha realizado principalmente en:
- **Windows 10**
- **Chrome**
- entorno Flutter

La prueba en Android/iPhone queda como siguiente fase del proyecto.

---

## Estructura general de la app

- **Inicio** → dashboard principal
- **Progreso** → seguimiento corporal y gráfica
- **Biblioteca** → ejercicios por grupo muscular
- **Historial** → entrenamientos guardados

---

## Instalación

### Requisitos
- Flutter instalado
- VS Code o Android Studio
- Dependencias descargadas con `flutter pub get`

### Ejecutar el proyecto
```bash
flutter pub get
flutter run
