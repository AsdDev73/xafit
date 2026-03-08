import '../models/exercise.dart';

class ExerciseCatalog {
  static final List<Exercise> allExercises = [
    // PECHO
    const Exercise(
      id: 'chest_1',
      name: 'Press banca con barra',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'barra', 'empuje', 'pecho medio'],
    ),
    const Exercise(
      id: 'chest_2',
      name: 'Press banca en Smith',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'smith', 'empuje', 'guiado'],
    ),
    const Exercise(
      id: 'chest_3',
      name: 'Press inclinado con barra',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'barra', 'inclinado', 'pecho superior'],
    ),
    const Exercise(
      id: 'chest_4',
      name: 'Press inclinado con mancuernas',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'mancuernas', 'inclinado', 'pecho superior'],
    ),
    const Exercise(
      id: 'chest_5',
      name: 'Press declinado con barra',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'barra', 'declinado', 'pecho inferior'],
    ),
    const Exercise(
      id: 'chest_6',
      name: 'Press en máquina',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'maquina', 'empuje', 'guiado'],
    ),
    const Exercise(
      id: 'chest_7',
      name: 'Aperturas con mancuernas',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'mancuernas', 'apertura', 'estiramiento'],
    ),
    const Exercise(
      id: 'chest_8',
      name: 'Aperturas en polea',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'polea', 'apertura', 'tension constante'],
    ),
    const Exercise(
      id: 'chest_9',
      name: 'Peck deck',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'maquina', 'apertura', 'pecho'],
    ),
    const Exercise(
      id: 'chest_10',
      name: 'Fondos en paralelas',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'peso corporal', 'empuje', 'pecho inferior'],
    ),

    // ESPALDA
    const Exercise(
      id: 'back_1',
      name: 'Dominadas pronas',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'peso corporal', 'tiron vertical', 'dorsal'],
    ),
    const Exercise(
      id: 'back_2',
      name: 'Dominadas supinas',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'peso corporal', 'tiron vertical', 'biceps'],
    ),
    const Exercise(
      id: 'back_3',
      name: 'Jalón al pecho',
      muscleGroup: 'Espalda',
      tags: ['polea', 'tiron vertical', 'dorsal', 'guiado'],
    ),
    const Exercise(
      id: 'back_4',
      name: 'Jalón con agarre estrecho',
      muscleGroup: 'Espalda',
      tags: ['polea', 'tiron vertical', 'dorsal', 'estrecho'],
    ),
    const Exercise(
      id: 'back_5',
      name: 'Remo con barra',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'barra', 'tiron horizontal', 'espesor'],
    ),
    const Exercise(
      id: 'back_6',
      name: 'Remo con mancuerna',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'mancuernas', 'tiron horizontal', 'unilateral'],
    ),
    const Exercise(
      id: 'back_7',
      name: 'Remo en máquina',
      muscleGroup: 'Espalda',
      tags: ['maquina', 'tiron horizontal', 'espesor', 'guiado'],
    ),
    const Exercise(
      id: 'back_8',
      name: 'Remo en polea baja',
      muscleGroup: 'Espalda',
      tags: ['polea', 'tiron horizontal', 'espesor', 'guiado'],
    ),
    const Exercise(
      id: 'back_9',
      name: 'Pullover en polea',
      muscleGroup: 'Espalda',
      tags: ['aislado', 'polea', 'dorsal', 'estiramiento'],
    ),
    const Exercise(
      id: 'back_10',
      name: 'Peso muerto',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'barra', 'cadena posterior', 'fuerza'],
    ),

    // PIERNA
    const Exercise(
      id: 'leg_1',
      name: 'Sentadilla con barra',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'barra', 'cuadriceps', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_2',
      name: 'Sentadilla en Smith',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'smith', 'cuadriceps', 'guiado'],
    ),
    const Exercise(
      id: 'leg_3',
      name: 'Prensa',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'maquina', 'cuadriceps', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_4',
      name: 'Peso muerto rumano',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'barra', 'femoral', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_5',
      name: 'Zancadas con mancuernas',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'mancuernas', 'unilateral', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_6',
      name: 'Bulgarian split squat',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'unilateral', 'cuadriceps', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_7',
      name: 'Extensión de cuadriceps',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'cuadriceps', 'guiado'],
    ),
    const Exercise(
      id: 'leg_8',
      name: 'Curl femoral tumbado',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'femoral', 'guiado'],
    ),
    const Exercise(
      id: 'leg_9',
      name: 'Curl femoral sentado',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'femoral', 'guiado'],
    ),
    const Exercise(
      id: 'leg_10',
      name: 'Hip thrust',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'barra', 'gluteo', 'cadena posterior'],
    ),
    const Exercise(
      id: 'leg_11',
      name: 'Gemelos de pie',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'gemelo', 'maquina', 'de pie'],
    ),
    const Exercise(
      id: 'leg_12',
      name: 'Gemelos sentado',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'gemelo', 'maquina', 'sentado'],
    ),

    // HOMBRO
    const Exercise(
      id: 'shoulder_1',
      name: 'Press militar con barra',
      muscleGroup: 'Hombro',
      tags: ['compuesto', 'barra', 'empuje', 'deltoide frontal'],
    ),
    const Exercise(
      id: 'shoulder_2',
      name: 'Press militar con mancuernas',
      muscleGroup: 'Hombro',
      tags: ['compuesto', 'mancuernas', 'empuje', 'deltoide frontal'],
    ),
    const Exercise(
      id: 'shoulder_3',
      name: 'Press en máquina',
      muscleGroup: 'Hombro',
      tags: ['compuesto', 'maquina', 'empuje', 'guiado'],
    ),
    const Exercise(
      id: 'shoulder_4',
      name: 'Elevaciones laterales con mancuernas',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'mancuernas', 'deltoide lateral'],
    ),
    const Exercise(
      id: 'shoulder_5',
      name: 'Elevaciones laterales en polea',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'polea', 'deltoide lateral', 'unilateral'],
    ),
    const Exercise(
      id: 'shoulder_6',
      name: 'Elevaciones frontales',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'mancuernas', 'deltoide frontal'],
    ),
    const Exercise(
      id: 'shoulder_7',
      name: 'Pajaros con mancuernas',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'mancuernas', 'deltoide posterior'],
    ),
    const Exercise(
      id: 'shoulder_8',
      name: 'Pajaros en peck deck',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'maquina', 'deltoide posterior'],
    ),
    const Exercise(
      id: 'shoulder_9',
      name: 'Face pull',
      muscleGroup: 'Hombro',
      tags: ['polea', 'deltoide posterior', 'trapecio', 'salud hombro'],
    ),

    // BICEPS
    const Exercise(
      id: 'biceps_1',
      name: 'Curl con barra recta',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'barra', 'biceps', 'basico'],
    ),
    const Exercise(
      id: 'biceps_2',
      name: 'Curl con barra Z',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'barra z', 'biceps', 'basico'],
    ),
    const Exercise(
      id: 'biceps_3',
      name: 'Curl con mancuernas',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'mancuernas', 'biceps'],
    ),
    const Exercise(
      id: 'biceps_4',
      name: 'Curl alterno',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'mancuernas', 'unilateral'],
    ),
    const Exercise(
      id: 'biceps_5',
      name: 'Curl martillo',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'mancuernas', 'braquial', 'antebrazo'],
    ),
    const Exercise(
      id: 'biceps_6',
      name: 'Curl en banco inclinado',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'mancuernas', 'estiramiento', 'biceps'],
    ),
    const Exercise(
      id: 'biceps_7',
      name: 'Curl en polea',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'polea', 'tension constante', 'biceps'],
    ),
    const Exercise(
      id: 'biceps_8',
      name: 'Curl predicador',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'maquina', 'predicador', 'biceps'],
    ),

    // TRICEPS
    const Exercise(
      id: 'triceps_1',
      name: 'Press frances con barra Z',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'barra z', 'triceps', 'tumado'],
    ),
    const Exercise(
      id: 'triceps_2',
      name: 'Extensión en polea con cuerda',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'polea', 'triceps', 'cuerda'],
    ),
    const Exercise(
      id: 'triceps_3',
      name: 'Extensión en polea con barra',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'polea', 'triceps', 'barra'],
    ),
    const Exercise(
      id: 'triceps_4',
      name: 'Extensión por encima de la cabeza con mancuerna',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'mancuernas', 'triceps', 'cabeza larga'],
    ),
    const Exercise(
      id: 'triceps_5',
      name: 'Extensión por encima de la cabeza en polea',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'polea', 'triceps', 'cabeza larga'],
    ),
    const Exercise(
      id: 'triceps_6',
      name: 'Fondos para triceps',
      muscleGroup: 'Tríceps',
      tags: ['compuesto', 'peso corporal', 'empuje', 'triceps'],
    ),
    const Exercise(
      id: 'triceps_7',
      name: 'Press cerrado con barra',
      muscleGroup: 'Tríceps',
      tags: ['compuesto', 'barra', 'empuje', 'triceps'],
    ),

    // ABDOMEN
    const Exercise(
      id: 'abs_1',
      name: 'Crunch en suelo',
      muscleGroup: 'Abdomen',
      tags: ['aislado', 'peso corporal', 'core'],
    ),
    const Exercise(
      id: 'abs_2',
      name: 'Crunch en maquina',
      muscleGroup: 'Abdomen',
      tags: ['aislado', 'maquina', 'core'],
    ),
    const Exercise(
      id: 'abs_3',
      name: 'Elevaciones de piernas',
      muscleGroup: 'Abdomen',
      tags: ['peso corporal', 'core', 'abdomen inferior'],
    ),
    const Exercise(
      id: 'abs_4',
      name: 'Plancha',
      muscleGroup: 'Abdomen',
      tags: ['isometrico', 'core', 'peso corporal'],
    ),
    const Exercise(
      id: 'abs_5',
      name: 'Plancha lateral',
      muscleGroup: 'Abdomen',
      tags: ['isometrico', 'core', 'oblicuos'],
    ),
    const Exercise(
      id: 'abs_6',
      name: 'Russian twist',
      muscleGroup: 'Abdomen',
      tags: ['oblicuos', 'rotacion', 'core'],
    ),
    const Exercise(
      id: 'abs_7',
      name: 'Ab wheel',
      muscleGroup: 'Abdomen',
      tags: ['core', 'rueda', 'avanzado'],
    ),
    const Exercise(
      id: 'abs_8',
      name: 'Encogimientos en polea',
      muscleGroup: 'Abdomen',
      tags: ['polea', 'core', 'resistencia'],
    ),
  ];

  static List<Exercise> byMuscleGroup(String muscleGroup) {
    return allExercises
        .where((exercise) => exercise.muscleGroup == muscleGroup)
        .toList();
  }

  static int get totalCount => allExercises.length;
}
