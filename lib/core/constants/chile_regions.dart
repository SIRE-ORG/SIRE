/// Lista canónica de las 16 regiones de Chile.
///
/// Fuente única compartida entre el selector manual de región del
/// onboarding ([LocationScreen]) y los selectores de región de los
/// formularios de publicación (crear/editar): antes cada uno tenía su
/// propia copia (o, peor, un campo de texto libre), lo que ensuciaba el
/// filtro de región del feed con valores no estandarizados.
const List<String> chileRegions = <String>[
  'Región de Arica y Parinacota',
  'Región de Tarapacá',
  'Región de Antofagasta',
  'Región de Atacama',
  'Región de Coquimbo',
  'Región de Valparaíso',
  'Región Metropolitana',
  "Región del Libertador General Bernardo O'Higgins",
  'Región del Maule',
  'Región de Ñuble',
  'Región del Biobío',
  'Región de La Araucanía',
  'Región de Los Ríos',
  'Región de Los Lagos',
  'Región de Aysén',
  'Región de Magallanes',
];
