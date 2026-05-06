/// Los 14 alérgenos del Anexo II del Reglamento UE 1169/2011 sobre información
/// alimentaria al consumidor.
///
/// Son declaraciones negativas de composición ("este plato contiene...") y
/// son obligatorios de declarar en restauración profesional. En YumYum la
/// transacción es entre vecinos pero seguimos el mismo estándar para
/// proteger a personas con celiaquía, alergias graves, etc.
abstract final class AlergenosUe {
  static const gluten = 'Gluten';
  static const crustaceos = 'Crustáceos';
  static const huevo = 'Huevo';
  static const pescado = 'Pescado';
  static const cacahuetes = 'Cacahuetes';
  static const soja = 'Soja';
  static const lacteos = 'Lácteos';
  static const frutosCascara = 'Frutos de cáscara';
  static const apio = 'Apio';
  static const mostaza = 'Mostaza';
  static const sesamo = 'Sésamo';
  static const sulfitos = 'Sulfitos';
  static const altramuces = 'Altramuces';
  static const moluscos = 'Moluscos';

  static const todos = <String>[
    gluten,
    crustaceos,
    huevo,
    pescado,
    cacahuetes,
    soja,
    lacteos,
    frutosCascara,
    apio,
    mostaza,
    sesamo,
    sulfitos,
    altramuces,
    moluscos,
  ];
}
