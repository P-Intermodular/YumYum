import 'package:flutter/material.dart';

/// Categoría única del producto. Obligatoria al publicar; el set de valores
/// está validado en backend mediante un CHECK constraint sobre `productos`.
abstract final class CategoriaProducto {
  static const cuchara = 'cuchara';
  static const arrocesPastas = 'arroces_pastas';
  static const carnes = 'carnes';
  static const pescados = 'pescados';
  static const verdurasEnsaladas = 'verduras_ensaladas';
  static const tapasAperitivos = 'tapas_aperitivos';
  static const panMasas = 'pan_masas';
  static const postresDulces = 'postres_dulces';
  static const bebidasLicores = 'bebidas_licores';
  static const frescosHuerto = 'frescos_huerto';
  static const quesosEmbutidos = 'quesos_embutidos';
  static const despensa = 'despensa';
  static const otros = 'otros';

  /// Listado canónico para UI: valor backend + label visible + icono Material.
  static const todas = <CategoriaInfo>[
    CategoriaInfo(cuchara, 'Cuchara', Icons.soup_kitchen_outlined),
    CategoriaInfo(arrocesPastas, 'Arroces y pastas', Icons.ramen_dining_outlined),
    CategoriaInfo(carnes, 'Carnes', Icons.lunch_dining_outlined),
    CategoriaInfo(pescados, 'Pescados', Icons.set_meal_outlined),
    CategoriaInfo(verdurasEnsaladas, 'Verduras y ensaladas', Icons.eco_outlined),
    CategoriaInfo(tapasAperitivos, 'Tapas y aperitivos', Icons.tapas_outlined),
    CategoriaInfo(panMasas, 'Pan y masas', Icons.bakery_dining_outlined),
    CategoriaInfo(postresDulces, 'Postres y dulces', Icons.cake_outlined),
    CategoriaInfo(bebidasLicores, 'Bebidas y licores', Icons.local_bar_outlined),
    CategoriaInfo(frescosHuerto, 'Frescos del huerto', Icons.grass_outlined),
    CategoriaInfo(quesosEmbutidos, 'Quesos y embutidos', Icons.kebab_dining_outlined),
    CategoriaInfo(despensa, 'Despensa', Icons.kitchen_outlined),
    CategoriaInfo(otros, 'Otros', Icons.more_horiz_outlined),
  ];

  /// Etiqueta legible para mostrar en UI; fallback "Otros" si no se encuentra.
  static String label(String valor) => _infoPara(valor)?.label ?? 'Otros';

  /// Icono asociado a la categoría; fallback Icons.more_horiz_outlined.
  static IconData icono(String valor) =>
      _infoPara(valor)?.icono ?? Icons.more_horiz_outlined;

  static CategoriaInfo? _infoPara(String valor) {
    for (final c in todas) {
      if (c.valor == valor) return c;
    }
    return null;
  }
}

class CategoriaInfo {
  final String valor;
  final String label;
  final IconData icono;

  const CategoriaInfo(this.valor, this.label, this.icono);
}
