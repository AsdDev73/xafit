import '../models/exercise.dart';

class ExerciseCatalog {
  static final List<Exercise> allExercises = [
    // =========================
    // PECHO
    // =========================
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
    const Exercise(
      id: 'chest_11',
      name: 'Press plano con mancuernas',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'mancuernas', 'empuje', 'pecho medio'],
    ),
    const Exercise(
      id: 'chest_12',
      name: 'Press declinado con mancuernas',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'mancuernas', 'declinado', 'pecho inferior'],
    ),
    const Exercise(
      id: 'chest_13',
      name: 'Press convergente en máquina',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'maquina', 'empuje', 'convergente'],
    ),
    const Exercise(
      id: 'chest_14',
      name: 'Press unilateral en máquina',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'maquina', 'unilateral', 'pecho'],
    ),
    const Exercise(
      id: 'chest_15',
      name: 'Cruce en polea alta',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'polea', 'pecho inferior', 'tension constante'],
    ),
    const Exercise(
      id: 'chest_16',
      name: 'Cruce en polea baja',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'polea', 'pecho superior', 'tension constante'],
    ),
    const Exercise(
      id: 'chest_17',
      name: 'Cruce en polea unilateral',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'polea', 'unilateral', 'tension constante'],
    ),
    const Exercise(
      id: 'chest_18',
      name: 'Press inclinado en Smith',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'smith', 'inclinado', 'guiado'],
    ),
    const Exercise(
      id: 'chest_19',
      name: 'Flexiones',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'peso corporal', 'empuje', 'basico'],
    ),
    const Exercise(
      id: 'chest_20',
      name: 'Flexiones lastradas',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'peso corporal', 'lastre', 'empuje'],
    ),
    const Exercise(
      id: 'chest_21',
      name: 'Press en máquina inclinada',
      muscleGroup: 'Pecho',
      tags: ['compuesto', 'maquina', 'inclinado', 'guiado'],
    ),
    const Exercise(
      id: 'chest_22',
      name: 'Svend press',
      muscleGroup: 'Pecho',
      tags: ['aislado', 'disco', 'contraccion', 'pecho'],
    ),

    // =========================
    // ESPALDA
    // =========================
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
    const Exercise(
      id: 'back_11',
      name: 'Dominadas neutras',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'peso corporal', 'tiron vertical', 'dorsal'],
    ),
    const Exercise(
      id: 'back_12',
      name: 'Jalón neutro',
      muscleGroup: 'Espalda',
      tags: ['polea', 'tiron vertical', 'dorsal', 'neutro'],
    ),
    const Exercise(
      id: 'back_13',
      name: 'Jalón unilateral',
      muscleGroup: 'Espalda',
      tags: ['polea', 'tiron vertical', 'unilateral', 'dorsal'],
    ),
    const Exercise(
      id: 'back_14',
      name: 'Remo unilateral en polea',
      muscleGroup: 'Espalda',
      tags: ['polea', 'tiron horizontal', 'unilateral', 'espesor'],
    ),
    const Exercise(
      id: 'back_15',
      name: 'Remo con pecho apoyado',
      muscleGroup: 'Espalda',
      tags: ['maquina', 'tiron horizontal', 'espesor', 'estable'],
    ),
    const Exercise(
      id: 'back_16',
      name: 'Remo en T',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'maquina', 'tiron horizontal', 'espesor'],
    ),
    const Exercise(
      id: 'back_17',
      name: 'Remo Meadows',
      muscleGroup: 'Espalda',
      tags: ['barra', 'unilateral', 'tiron horizontal', 'espesor'],
    ),
    const Exercise(
      id: 'back_18',
      name: 'Rack pull',
      muscleGroup: 'Espalda',
      tags: ['compuesto', 'barra', 'cadena posterior', 'fuerza'],
    ),
    const Exercise(
      id: 'back_19',
      name: 'Pulldown con brazos rectos',
      muscleGroup: 'Espalda',
      tags: ['polea', 'aislado', 'dorsal', 'estiramiento'],
    ),
    const Exercise(
      id: 'back_20',
      name: 'Remo invertido',
      muscleGroup: 'Espalda',
      tags: ['peso corporal', 'tiron horizontal', 'basico', 'espalda'],
    ),
    const Exercise(
      id: 'back_21',
      name: 'Pullover con mancuerna',
      muscleGroup: 'Espalda',
      tags: ['mancuernas', 'aislado', 'dorsal', 'estiramiento'],
    ),
    const Exercise(
      id: 'back_22',
      name: 'Remo en máquina convergente',
      muscleGroup: 'Espalda',
      tags: ['maquina', 'tiron horizontal', 'convergente', 'espesor'],
    ),

    // =========================
    // PIERNA
    // =========================
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
    const Exercise(
      id: 'leg_13',
      name: 'Sentadilla frontal',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'barra', 'cuadriceps', 'core'],
    ),
    const Exercise(
      id: 'leg_14',
      name: 'Hack squat',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'maquina', 'cuadriceps', 'guiado'],
    ),
    const Exercise(
      id: 'leg_15',
      name: 'Prensa unilateral',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'maquina', 'unilateral', 'cuadriceps'],
    ),
    const Exercise(
      id: 'leg_16',
      name: 'Extensión de cuadriceps unilateral',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'unilateral', 'cuadriceps'],
    ),
    const Exercise(
      id: 'leg_17',
      name: 'Curl femoral unilateral',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'unilateral', 'femoral'],
    ),
    const Exercise(
      id: 'leg_18',
      name: 'Peso muerto rumano con mancuernas',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'mancuernas', 'femoral', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_19',
      name: 'Peso muerto rumano a una pierna',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'mancuernas', 'unilateral', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_20',
      name: 'B-stance RDL',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'barra', 'unilateral', 'femoral'],
    ),
    const Exercise(
      id: 'leg_21',
      name: 'Step-up',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'mancuernas', 'unilateral', 'gluteo'],
    ),
    const Exercise(
      id: 'leg_22',
      name: 'Zancada caminando',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'mancuernas', 'unilateral', 'cuadriceps'],
    ),
    const Exercise(
      id: 'leg_23',
      name: 'Sentadilla goblet',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'mancuernas', 'cuadriceps', 'basico'],
    ),
    const Exercise(
      id: 'leg_24',
      name: 'Hip thrust unilateral',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'unilateral', 'gluteo', 'peso corporal'],
    ),
    const Exercise(
      id: 'leg_25',
      name: 'Patada de glúteo en polea',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'polea', 'gluteo', 'unilateral'],
    ),
    const Exercise(
      id: 'leg_26',
      name: 'Abductores en máquina',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'gluteo', 'abduccion'],
    ),
    const Exercise(
      id: 'leg_27',
      name: 'Aductores en máquina',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'maquina', 'aductores', 'guiado'],
    ),
    const Exercise(
      id: 'leg_28',
      name: 'Buenos días',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'barra', 'cadena posterior', 'femoral'],
    ),
    const Exercise(
      id: 'leg_29',
      name: 'Puente de glúteo',
      muscleGroup: 'Pierna',
      tags: ['compuesto', 'peso corporal', 'gluteo', 'basico'],
    ),
    const Exercise(
      id: 'leg_30',
      name: 'Sissy squat',
      muscleGroup: 'Pierna',
      tags: ['aislado', 'peso corporal', 'cuadriceps', 'avanzado'],
    ),

    // =========================
    // HOMBRO
    // =========================
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
      name: 'Pájaros con mancuernas',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'mancuernas', 'deltoide posterior'],
    ),
    const Exercise(
      id: 'shoulder_8',
      name: 'Pájaros en peck deck',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'maquina', 'deltoide posterior'],
    ),
    const Exercise(
      id: 'shoulder_9',
      name: 'Face pull',
      muscleGroup: 'Hombro',
      tags: ['polea', 'deltoide posterior', 'trapecio', 'salud hombro'],
    ),
    const Exercise(
      id: 'shoulder_10',
      name: 'Arnold press',
      muscleGroup: 'Hombro',
      tags: ['compuesto', 'mancuernas', 'empuje', 'deltoide frontal'],
    ),
    const Exercise(
      id: 'shoulder_11',
      name: 'Press unilateral con mancuerna',
      muscleGroup: 'Hombro',
      tags: ['compuesto', 'mancuernas', 'unilateral', 'core'],
    ),
    const Exercise(
      id: 'shoulder_12',
      name: 'Press en Smith',
      muscleGroup: 'Hombro',
      tags: ['compuesto', 'smith', 'empuje', 'guiado'],
    ),
    const Exercise(
      id: 'shoulder_13',
      name: 'Elevación lateral en máquina',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'maquina', 'deltoide lateral', 'guiado'],
    ),
    const Exercise(
      id: 'shoulder_14',
      name: 'Elevación lateral inclinada',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'mancuernas', 'deltoide lateral', 'estiramiento'],
    ),
    const Exercise(
      id: 'shoulder_15',
      name: 'Elevación frontal en polea',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'polea', 'deltoide frontal', 'unilateral'],
    ),
    const Exercise(
      id: 'shoulder_16',
      name: 'Reverse fly en polea',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'polea', 'deltoide posterior', 'tension constante'],
    ),
    const Exercise(
      id: 'shoulder_17',
      name: 'Reverse fly unilateral en polea',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'polea', 'unilateral', 'deltoide posterior'],
    ),
    const Exercise(
      id: 'shoulder_18',
      name: 'Y-raise',
      muscleGroup: 'Hombro',
      tags: ['aislado', 'mancuernas', 'estabilidad', 'trapecio'],
    ),

    // =========================
    // BÍCEPS
    // =========================
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
    const Exercise(
      id: 'biceps_9',
      name: 'Curl concentración',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'mancuernas', 'unilateral', 'contraccion'],
    ),
    const Exercise(
      id: 'biceps_10',
      name: 'Spider curl',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'barra z', 'biceps', 'contraccion'],
    ),
    const Exercise(
      id: 'biceps_11',
      name: 'Bayesian curl',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'polea', 'unilateral', 'estiramiento'],
    ),
    const Exercise(
      id: 'biceps_12',
      name: 'Curl predicador unilateral en polea',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'polea', 'unilateral', 'predicador'],
    ),
    const Exercise(
      id: 'biceps_13',
      name: 'Curl martillo cruzado',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'mancuernas', 'unilateral', 'braquial'],
    ),
    const Exercise(
      id: 'biceps_14',
      name: 'Curl inverso con barra',
      muscleGroup: 'Bíceps',
      tags: ['aislado', 'barra', 'antebrazo', 'braquiorradial'],
    ),

    // =========================
    // TRÍCEPS
    // =========================
    const Exercise(
      id: 'triceps_1',
      name: 'Press francés con barra Z',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'barra z', 'triceps', 'tumbado'],
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
      name: 'Fondos para tríceps',
      muscleGroup: 'Tríceps',
      tags: ['compuesto', 'peso corporal', 'empuje', 'triceps'],
    ),
    const Exercise(
      id: 'triceps_7',
      name: 'Press cerrado con barra',
      muscleGroup: 'Tríceps',
      tags: ['compuesto', 'barra', 'empuje', 'triceps'],
    ),
    const Exercise(
      id: 'triceps_8',
      name: 'Pushdown unilateral',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'polea', 'unilateral', 'triceps'],
    ),
    const Exercise(
      id: 'triceps_9',
      name: 'Extensión unilateral por encima de la cabeza en polea',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'polea', 'unilateral', 'cabeza larga'],
    ),
    const Exercise(
      id: 'triceps_10',
      name: 'Kickback con mancuerna',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'mancuernas', 'unilateral', 'contraccion'],
    ),
    const Exercise(
      id: 'triceps_11',
      name: 'Press JM',
      muscleGroup: 'Tríceps',
      tags: ['compuesto', 'barra', 'triceps', 'fuerza'],
    ),
    const Exercise(
      id: 'triceps_12',
      name: 'Press francés con mancuernas',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'mancuernas', 'triceps', 'tumbado'],
    ),
    const Exercise(
      id: 'triceps_13',
      name: 'Pushdown invertido',
      muscleGroup: 'Tríceps',
      tags: ['aislado', 'polea', 'triceps', 'agarre inverso'],
    ),
    const Exercise(
      id: 'triceps_14',
      name: 'Fondos en banco',
      muscleGroup: 'Tríceps',
      tags: ['compuesto', 'peso corporal', 'triceps', 'basico'],
    ),

    // =========================
    // ABDOMEN
    // =========================
    const Exercise(
      id: 'abs_1',
      name: 'Crunch en suelo',
      muscleGroup: 'Abdomen',
      tags: ['aislado', 'peso corporal', 'core'],
    ),
    const Exercise(
      id: 'abs_2',
      name: 'Crunch en máquina',
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
    const Exercise(
      id: 'abs_9',
      name: 'Pallof press',
      muscleGroup: 'Abdomen',
      tags: ['polea', 'core', 'anti rotacion', 'estabilidad'],
    ),
    const Exercise(
      id: 'abs_10',
      name: 'Woodchopper en polea',
      muscleGroup: 'Abdomen',
      tags: ['polea', 'oblicuos', 'rotacion', 'core'],
    ),
    const Exercise(
      id: 'abs_11',
      name: 'Crunch declinado',
      muscleGroup: 'Abdomen',
      tags: ['peso corporal', 'core', 'abdomen'],
    ),
    const Exercise(
      id: 'abs_12',
      name: 'Elevación de rodillas colgado',
      muscleGroup: 'Abdomen',
      tags: ['peso corporal', 'core', 'abdomen inferior'],
    ),
    const Exercise(
      id: 'abs_13',
      name: 'Hollow body hold',
      muscleGroup: 'Abdomen',
      tags: ['isometrico', 'core', 'estabilidad'],
    ),
    const Exercise(
      id: 'abs_14',
      name: 'Dead bug',
      muscleGroup: 'Abdomen',
      tags: ['core', 'estabilidad', 'peso corporal'],
    ),
    const Exercise(
      id: 'abs_15',
      name: 'Mountain climbers',
      muscleGroup: 'Abdomen',
      tags: ['core', 'dinamico', 'peso corporal'],
    ),
    const Exercise(
      id: 'abs_16',
      name: 'Toe touches',
      muscleGroup: 'Abdomen',
      tags: ['peso corporal', 'core', 'abdomen superior'],
    ),
  ];

  static List<Exercise> byMuscleGroup(String muscleGroup) {
    return allExercises
        .where((exercise) => exercise.muscleGroup == muscleGroup)
        .toList();
  }

  static int get totalCount => allExercises.length;
}
