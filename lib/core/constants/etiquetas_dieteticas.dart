/// Etiquetas dietéticas que el cocinero puede declarar como **claims positivos**
/// del plato. Multi-select opcional al publicar; sirven para filtrar el feed.
///
/// No confundir con `AlergenosUe`: estos son declaraciones negativas de
/// composición ("contiene gluten"). Las etiquetas son afirmaciones del cocinero
/// sobre las propiedades del plato ("este plato es vegano").
abstract final class EtiquetasDieteticas {
  static const vegetariano = 'Vegetariano';
  static const vegano = 'Vegano';
  static const sinGluten = 'Sin gluten';
  static const sinLactosa = 'Sin lactosa';
  static const halal = 'Halal';
  static const kosher = 'Kosher';
  static const picante = 'Picante';

  static const todas = <String>[
    vegetariano,
    vegano,
    sinGluten,
    sinLactosa,
    halal,
    kosher,
    picante,
  ];
}
