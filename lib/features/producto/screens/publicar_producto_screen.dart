import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/alergenos_ue.dart';
import '../../../core/constants/categorias_producto.dart';
import '../../../core/constants/estados_app.dart';
import '../../../core/constants/etiquetas_dieteticas.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/providers_refresher.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/selector_ubicacion_mapa.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/datos_publicacion_producto.dart';
import '../controllers/publicar_producto_controller.dart';

/// Pantalla de creación de nuevas ofertas con la estética figma.
class PublicarProductoScreen extends ConsumerStatefulWidget {
  const PublicarProductoScreen({super.key});

  @override
  ConsumerState<PublicarProductoScreen> createState() =>
      _PublicarProductoScreenState();
}

class _PublicarProductoScreenState
    extends ConsumerState<PublicarProductoScreen> {
  static const double _zoomMapa = 16;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _racionesController = TextEditingController(text: '1');
  final _picker = ImagePicker();
  final _mapController = MapController();

  Uint8List? _bytesImagen;
  String _extensionImagen = 'jpg';
  String _tipo = TipoOferta.intercambio;
  String? _categoria;
  final Set<String> _etiquetas = {};
  final Set<String> _alergenos = {};
  bool _sinAlergenos = false;
  LatLng? _ubicacionElegida;
  bool _mapaCentradoEnPerfil = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _racionesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    final imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (imagen == null || !mounted) return;

    final bytes = await imagen.readAsBytes();
    if (!mounted) return;

    final extension = imagen.name.split('.').last;
    setState(() {
      _bytesImagen = bytes;
      _extensionImagen = extension.isEmpty ? 'jpg' : extension;
    });
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoria == null) {
      mostrarError(context, Exception('Elige una categoría para tu plato.'));
      return;
    }

    if (_alergenos.isEmpty && !_sinAlergenos) {
      mostrarError(
        context,
        Exception(
          'Declara los alérgenos o marca "Sin alérgenos del Anexo II".',
        ),
      );
      return;
    }

    final ubicacion = _ubicacionElegida;
    if (ubicacion == null) {
      mostrarError(
        context,
        Exception('Configura tu ubicación en el perfil antes de publicar.'),
      );
      return;
    }

    final raciones = int.tryParse(_racionesController.text.trim()) ?? 0;
    if (raciones < 1) {
      mostrarError(
        context,
        Exception('Indica cuántas raciones tienes (mínimo 1).'),
      );
      return;
    }

    try {
      await ref.read(publicarProductoControllerProvider.notifier).publicar(
            DatosPublicacionProducto(
              titulo: _tituloController.text.trim(),
              descripcion: _descripcionController.text.trim(),
              tipo: _tipo,
              precio: _tipo == TipoOferta.venta
                  ? double.tryParse(_precioController.text.replaceAll(',', '.'))
                  : null,
              categoria: _categoria!,
              etiquetas: _etiquetas.toList(),
              alergenos: _sinAlergenos ? const [] : _alergenos.toList(),
              sinAlergenosDeclarados: _sinAlergenos,
              raciones: raciones,
              bytesImagen: _bytesImagen,
              extensionImagen: _extensionImagen,
              ubicacionExacta: ubicacion,
            ),
          );

      if (mounted) {
        context.go(RutasApp.inicio);
        mostrarExito(context, 'Oferta publicada');
      }
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  void _seleccionarUbicacion(LatLng punto) {
    setState(() => _ubicacionElegida = punto);
  }

  Future<void> _usarUbicacionActual() async {
    ref.refrescarUbicacionActual();
    final ubicacionActual = await ref.read(ubicacionActualProvider.future);
    if (!mounted) return;

    if (ubicacionActual != null) {
      final punto = LatLng(ubicacionActual.latitud, ubicacionActual.longitud);
      setState(() => _ubicacionElegida = punto);
      _mapController.move(punto, _zoomMapa);
    } else {
      mostrarError(
        context,
        Exception('No se pudo obtener la ubicación actual.'),
      );
    }
  }

  void _restablecerAlPerfil(LatLng ubicacionPerfil) {
    setState(() => _ubicacionElegida = ubicacionPerfil);
    _mapController.move(ubicacionPerfil, _zoomMapa);
  }

  @override
  Widget build(BuildContext context) {
    final cargando = ref.watch(publicarProductoControllerProvider).isLoading;
    final usuario = ref.watch(autenticacionProvider).value;
    final ubicacionPerfil = usuario?.ubicacionPredeterminada;
    final bloqueado = ubicacionPerfil == null;
    final colors = context.yumColors;

    if (ubicacionPerfil != null && !_mapaCentradoEnPerfil) {
      _mapaCentradoEnPerfil = true;
      _ubicacionElegida ??= ubicacionPerfil;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(ubicacionPerfil, _zoomMapa);
      });
    }

    final ubicacionDifiereDePerfil = _ubicacionElegida != null &&
        ubicacionPerfil != null &&
        (_ubicacionElegida!.latitude != ubicacionPerfil.latitude ||
            _ubicacionElegida!.longitude != ubicacionPerfil.longitude);

    return Scaffold(
      appBar: const YumAppBar(title: 'Publicar plato', showBack: true),
      body: YumBackground(
        child: Form(
          key: _formKey,
          // Padding inferior generoso para que el botón "Publicar ahora"
          // quede por encima del bottom nav flotante del shell (~96 px).
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _buildFotoPicker(colors, cargando),
              const SizedBox(height: 18),
              const _LabelSeccion(text: 'Nombre del plato'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tituloController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoracion('Lentejas de la abuela'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              const _LabelSeccion(text: 'Descripción'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                decoration: _decoracion(
                  'Cómo está hecho, qué lleva, cualquier detalle útil…',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Cuenta algo sobre el plato'
                    : null,
              ),
              const SizedBox(height: 18),
              const _LabelSeccion(text: 'Tipo de oferta'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BotonTipo(
                      label: 'Intercambio',
                      icon: Icons.swap_horiz_rounded,
                      activo: _tipo == TipoOferta.intercambio,
                      onTap: () =>
                          setState(() => _tipo = TipoOferta.intercambio),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BotonTipo(
                      label: 'Venta',
                      icon: Icons.euro_rounded,
                      activo: _tipo == TipoOferta.venta,
                      onTap: () => setState(() => _tipo = TipoOferta.venta),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_tipo == TipoOferta.venta)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _LabelSeccion(text: 'Precio por ración'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _precioController,
                            decoration: _decoracion('4,50'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (_tipo != TipoOferta.venta) return null;
                              final parsed = double.tryParse(
                                (v ?? '').replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Introduce un precio válido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _LabelSeccion(text: 'Raciones'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _racionesController,
                            decoration: _decoracion('3'),
                            keyboardType: TextInputType.number,
                            validator: _validarRaciones,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                const _LabelSeccion(text: 'Raciones disponibles'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _racionesController,
                  decoration: _decoracion('3'),
                  keyboardType: TextInputType.number,
                  validator: _validarRaciones,
                ),
              ],
              const SizedBox(height: 16),
              const _LabelSeccion(text: 'Categoría'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in CategoriaProducto.todas)
                    _ChipCategoria(
                      label: cat.label,
                      icono: cat.icono,
                      activa: _categoria == cat.valor,
                      onTap: () => setState(() => _categoria = cat.valor),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _LabelSeccion(text: 'Etiquetas dietéticas (opcional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final etq in EtiquetasDieteticas.todas)
                    _ChipSeleccionable(
                      label: etq,
                      activa: _etiquetas.contains(etq),
                      tono: _TonoChip.olive,
                      onTap: () => setState(() {
                        if (_etiquetas.contains(etq)) {
                          _etiquetas.remove(etq);
                        } else {
                          _etiquetas.add(etq);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const _LabelSeccion(text: 'Alérgenos (Anexo II)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.paper,
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sin alérgenos del Anexo II',
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _sinAlergenos,
                          activeThumbColor: colors.terracotta,
                          onChanged: (v) => setState(() {
                            _sinAlergenos = v;
                            if (v) _alergenos.clear();
                          }),
                        ),
                      ],
                    ),
                    if (!_sinAlergenos) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Marca los que contiene tu plato.',
                        style: TextStyle(
                          color: colors.inkSoft,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in AlergenosUe.todos)
                            _ChipSeleccionable(
                              label: a,
                              activa: _alergenos.contains(a),
                              tono: _TonoChip.warn,
                              onTap: () => setState(() {
                                if (_alergenos.contains(a)) {
                                  _alergenos.remove(a);
                                } else {
                                  _alergenos.add(a);
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _LabelSeccion(text: 'Punto de recogida'),
              const SizedBox(height: 8),
              if (bloqueado)
                _BannerSinUbicacion(
                  onConfigurar: () => context.push(RutasApp.perfilUbicacion),
                )
              else ...[
                SelectorUbicacionMapa(
                  mapController: _mapController,
                  ubicacionElegida: _ubicacionElegida,
                  ubicacionUsuario: null,
                  gpsResolviendo: false,
                  gpsFallido: false,
                  onTap: cargando ? null : _seleccionarUbicacion,
                  titulo: 'Punto exacto de recogida',
                  subtitulo: 'Usando tu ubicación predeterminada. '
                      'Toca el mapa para ajustarla solo para este plato.',
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: cargando ? null : _usarUbicacionActual,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Usar mi ubicación actual'),
                    ),
                    if (ubicacionDifiereDePerfil)
                      TextButton.icon(
                        onPressed: cargando
                            ? null
                            : () => _restablecerAlPerfil(ubicacionPerfil),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Restablecer al perfil'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.olive.withValues(alpha: 0.10),
                  border: Border.all(
                    color: colors.olive.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 18,
                      color: colors.oliveDeep,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Al publicar aceptas las buenas prácticas de higiene y '
                        'asumes la responsabilidad sobre los alérgenos declarados.',
                        style: TextStyle(
                          color: colors.oliveDeep,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              YumButton(
                text: cargando ? 'Publicando…' : 'Publicar ahora',
                fullWidth: true,
                icon: cargando ? null : const Icon(Icons.add_rounded),
                onPressed: (cargando || bloqueado) ? null : _publicar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validarRaciones(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 1) {
      return 'Mínimo 1 ración';
    }
    return null;
  }

  InputDecoration _decoracion(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  Widget _buildFotoPicker(YumColors colors, bool cargando) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: cargando ? null : _elegirImagen,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(
              color: colors.line,
              style: _bytesImagen == null ? BorderStyle.solid : BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: _bytesImagen == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 36,
                        color: colors.inkSoft,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para añadir una foto',
                        style: TextStyle(
                          color: colors.inkSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Luz natural, plato bien servido',
                        style: TextStyle(
                          color: colors.inkSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_bytesImagen!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.ink.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Principal',
                          style: TextStyle(
                            color: colors.paper,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LabelSeccion extends StatelessWidget {
  final String text;
  const _LabelSeccion({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.inkSoft,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _BotonTipo extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool activo;
  final VoidCallback onTap;

  const _BotonTipo({
    required this.label,
    required this.icon,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        decoration: BoxDecoration(
          color: activo ? colors.terracotta : colors.paper,
          border: Border.all(
            color: activo ? colors.terracotta : colors.line,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: activo ? colors.paper : colors.ink,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: activo ? colors.paper : colors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String label;
  final IconData icono;
  final bool activa;
  final VoidCallback onTap;

  const _ChipCategoria({
    required this.label,
    required this.icono,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activa ? colors.terracotta : colors.paper,
          border: Border.all(
            color: activa ? colors.terracotta : colors.line,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 14,
              color: activa ? colors.paper : colors.inkSoft,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: activa ? colors.paper : colors.ink,
                fontSize: 12.5,
                fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


enum _TonoChip { olive, warn }

class _ChipSeleccionable extends StatelessWidget {
  final String label;
  final bool activa;
  final _TonoChip tono;
  final VoidCallback onTap;

  const _ChipSeleccionable({
    required this.label,
    required this.activa,
    required this.tono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    Color bg;
    Color border;
    Color textColor;
    if (activa) {
      switch (tono) {
        case _TonoChip.olive:
          bg = colors.olive.withValues(alpha: 0.18);
          border = colors.oliveDeep.withValues(alpha: 0.45);
          textColor = colors.oliveDeep;
          break;
        case _TonoChip.warn:
          bg = colors.mustard.withValues(alpha: 0.28);
          border = colors.mustard.withValues(alpha: 0.7);
          textColor = colors.ink;
          break;
      }
    } else {
      bg = colors.paper;
      border = colors.line;
      textColor = colors.inkSoft;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12.5,
            fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BannerSinUbicacion extends StatelessWidget {
  final VoidCallback onConfigurar;

  const _BannerSinUbicacion({required this.onConfigurar});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.mustard.withValues(alpha: 0.18),
        border: Border.all(color: colors.mustard.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            color: colors.terracottaDeep,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Configura tu ubicación predeterminada en el perfil antes de publicar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.ink, fontSize: 13),
          ),
          const SizedBox(height: 10),
          YumButton(
            text: 'Configurar ahora',
            variant: YumButtonVariant.ghost,
            onPressed: onConfigurar,
          ),
        ],
      ),
    );
  }
}
