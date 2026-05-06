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
import '../../../core/widgets/ui/label_seccion.dart';
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/providers/panel_pedidos_provider.dart';
import '../../../core/constants/estados_app.dart' as estados_pedido;
import '../controllers/datos_publicacion_producto.dart';
import '../controllers/publicar_producto_controller.dart';
import '../domain/entities/producto_model.dart';
import '../providers/producto_providers.dart';
import '../providers/producto_repository_provider.dart';

/// Pantalla dual de **publicación** y **edición** de un plato.
///
/// Si llega `productoId`, entra en modo edición: carga el producto + sus
/// imágenes ya persistidas, pre-rellena el formulario, cambia el título y el
/// CTA, y al guardar llama a `PublicarProductoController.actualizar` en lugar
/// de `publicar`.
class PublicarProductoScreen extends ConsumerStatefulWidget {
  final String? productoId;

  const PublicarProductoScreen({super.key, this.productoId});

  bool get esEdicion => productoId != null;

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

  static const _maxImagenes = 5;

  final List<ImagenSeleccionada> _imagenes = [];
  /// Ids de imágenes ya persistidas que el usuario ha quitado en esta sesión
  /// de edición. Se aplican al guardar.
  final Set<String> _idsImagenesAEliminar = {};
  String _tipo = TipoOferta.intercambio;
  String? _categoria;
  final Set<String> _etiquetas = {};
  final Set<String> _alergenos = {};
  bool _sinAlergenos = false;
  LatLng? _ubicacionElegida;
  bool _mapaCentradoEnPerfil = false;

  /// Estado de carga del producto en modo edición. `true` mientras se traen
  /// los datos iniciales para pre-rellenar el formulario.
  bool _cargandoEdicion = false;
  ProductoModel? _productoOriginal;

  /// Activa el render de errores en bloques no-Form (fotos, categoría,
  /// alérgenos) tras un intento de submit fallido. Antes del primer intento
  /// no mostramos errores para no agredir al usuario mientras aún está
  /// rellenando.
  bool _mostrarErroresBloques = false;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) {
      _cargandoEdicion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarParaEditar());
    }
  }

  /// Trae el producto y sus imágenes ya persistidas, y pre-rellena los
  /// campos. Si falla, muestra el error y vuelve atrás.
  Future<void> _cargarParaEditar() async {
    final id = widget.productoId!;
    try {
      final producto =
          await ref.read(productoDetalleProvider(id).future);
      if (!mounted || producto == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final imagenes = await ref
          .read(productoRepositoryProvider)
          .obtenerImagenesProducto(id);
      if (!mounted) return;

      setState(() {
        _productoOriginal = producto;
        _tituloController.text = producto.titulo;
        _descripcionController.text = producto.descripcion;
        _tipo = producto.tipo;
        _precioController.text = producto.precio?.toStringAsFixed(2) ?? '';
        _racionesController.text = producto.racionesTotales.toString();
        _categoria = producto.categoria;
        _etiquetas
          ..clear()
          ..addAll(producto.etiquetas);
        _alergenos
          ..clear()
          ..addAll(producto.alergenos);
        _sinAlergenos = producto.sinAlergenosDeclarados;
        _ubicacionElegida = producto.ubicacionPublica;
        _imagenes
          ..clear()
          ..addAll(imagenes);
        // El centrado del mapa también se da por hecho — la ubicación
        // pública ya viene en el producto.
        _mapaCentradoEnPerfil = true;
        _cargandoEdicion = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(producto.ubicacionPublica, _zoomMapa);
      });
    } catch (error) {
      if (!mounted) return;
      mostrarError(context, error);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _racionesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _anadirImagen() async {
    if (_imagenes.length >= _maxImagenes) return;

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
      _imagenes.add(
        ImagenSeleccionada(
          bytes: bytes,
          extension: extension.isEmpty ? 'jpg' : extension,
        ),
      );
    });
  }

  void _quitarImagen(int index) {
    final imagen = _imagenes[index];
    setState(() {
      // Si es una imagen ya persistida, marcamos su id para que el
      // repositorio la borre de la BD y de Storage al guardar la edición.
      if (imagen.esExistente) {
        _idsImagenesAEliminar.add(imagen.id!);
      }
      _imagenes.removeAt(index);
    });
  }

  Future<void> _guardar() async {
    // Validamos en bloque: TextFormField vía Form + validaciones de bloques
    // custom (fotos, categoría, alérgenos). Si algo falla, activamos los
    // errores inline y abortamos sin tocar nada en BD.
    final formOk = _formKey.currentState!.validate();
    final fotosOk = _imagenes.isNotEmpty;
    final categoriaOk = _categoria != null;
    final alergenosOk = _sinAlergenos || _alergenos.isNotEmpty;

    if (!formOk || !fotosOk || !categoriaOk || !alergenosOk) {
      setState(() => _mostrarErroresBloques = true);
      return;
    }

    final ubicacion = _ubicacionElegida;
    if (ubicacion == null) {
      // Caso especial: la sección de ubicación tiene su propio banner y
      // bloquea el botón si el perfil no tiene ubicación configurada.
      mostrarError(
        context,
        Exception('Configura tu ubicación en el perfil antes de publicar.'),
      );
      return;
    }

    final raciones = int.tryParse(_racionesController.text.trim()) ?? 0;

    if (widget.esEdicion) {
      await _aplicarEdicion(raciones, ubicacion);
    } else {
      await _publicarNuevo(raciones, ubicacion);
    }
  }

  Future<void> _publicarNuevo(int raciones, LatLng ubicacion) async {
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
              imagenes: List.unmodifiable(_imagenes),
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

  Future<void> _aplicarEdicion(int raciones, LatLng ubicacion) async {
    final original = _productoOriginal;
    if (original == null) return;
    final productoEditado = original.copyWith(
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
      racionesTotales: raciones,
      // Preservamos las raciones disponibles si bajamos el total al mismo o
      // por debajo, para no inflar stock vendido. Si el cocinero sube el
      // total, expandimos las disponibles proporcionalmente.
      racionesDisponibles: raciones >= original.racionesTotales
          ? original.racionesDisponibles + (raciones - original.racionesTotales)
          : raciones,
      ubicacionPublica: ubicacion,
    );

    try {
      await ref.read(publicarProductoControllerProvider.notifier).actualizar(
            productoId: widget.productoId!,
            producto: productoEditado,
            imagenesFinales: List.unmodifiable(_imagenes),
            idsImagenesAEliminar: _idsImagenesAEliminar.toList(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        mostrarExito(context, 'Cambios guardados');
      }
    } catch (error) {
      if (mounted) mostrarError(context, error);
    }
  }

  /// Detecta si el plato tiene actividad activa (solicitudes pendientes o
  /// transacciones aceptadas) para avisar al usuario de que la edición
  /// afecta solo a futuras solicitudes.
  bool _hayActividadActiva() {
    if (!widget.esEdicion) return false;
    final id = widget.productoId!;
    final panel = ref.watch(panelPedidosProvider).value;
    if (panel == null) return false;

    final tienePendientes = panel.solicitudesRecibidas.any((s) =>
        s.productoId == id &&
        s.estado == estados_pedido.EstadoSolicitud.pendiente);
    final tieneTxActiva = panel.transacciones.any((t) =>
        t.productoId == id &&
        (t.estado == estados_pedido.EstadoTransaccion.aceptada ||
            t.estado == estados_pedido.EstadoTransaccion.pendiente));
    return tienePendientes || tieneTxActiva;
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

    final esEdicion = widget.esEdicion;
    final tituloAppBar = esEdicion ? 'Editar plato' : 'Publicar plato';
    final textoCta = cargando
        ? (esEdicion ? 'Guardando…' : 'Publicando…')
        : (esEdicion ? 'Guardar cambios' : 'Publicar ahora');
    final iconoCta = cargando
        ? null
        : Icon(esEdicion ? Icons.check_rounded : Icons.add_rounded);
    final hayActividad = _hayActividadActiva();

    return Scaffold(
      appBar: YumAppBar(title: tituloAppBar, showBack: true),
      body: YumBackground(
        child: _cargandoEdicion
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          // Padding inferior generoso para que el botón "Publicar ahora"
          // quede por encima del bottom nav flotante del shell (~96 px).
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              if (hayActividad) ...[
                _BannerActividadActiva(),
                const SizedBox(height: 16),
              ],
              const LabelSeccion(text: 'Fotos del plato', obligatorio: true),
              const SizedBox(height: 8),
              _GridImagenes(
                imagenes: _imagenes,
                maxImagenes: _maxImagenes,
                deshabilitado: cargando,
                onAnadir: _anadirImagen,
                onQuitar: _quitarImagen,
              ),
              const SizedBox(height: 6),
              Text(
                'Hasta $_maxImagenes fotos. La primera será la portada.',
                style: TextStyle(color: colors.inkSoft, fontSize: 12),
              ),
              if (_mostrarErroresBloques && _imagenes.isEmpty)
                const ErrorInline(
                  text: 'Añade al menos una foto del plato.',
                ),
              const SizedBox(height: 18),
              const LabelSeccion(text: 'Nombre del plato', obligatorio: true),
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
              const LabelSeccion(text: 'Descripción', obligatorio: true),
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
              const LabelSeccion(text: 'Tipo de oferta', obligatorio: true),
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
                          const LabelSeccion(
                            text: 'Precio por ración',
                            obligatorio: true,
                          ),
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
                          const LabelSeccion(
                            text: 'Raciones',
                            obligatorio: true,
                          ),
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
                const LabelSeccion(
                  text: 'Raciones disponibles',
                  obligatorio: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _racionesController,
                  decoration: _decoracion('3'),
                  keyboardType: TextInputType.number,
                  validator: _validarRaciones,
                ),
              ],
              const SizedBox(height: 16),
              const LabelSeccion(text: 'Categoría', obligatorio: true),
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
              if (_mostrarErroresBloques && _categoria == null)
                const ErrorInline(
                  text: 'Elige la categoría que mejor describe tu plato.',
                ),
              const SizedBox(height: 16),
              const LabelSeccion(
                text: 'Etiquetas dietéticas',
                opcional: true,
              ),
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
              const LabelSeccion(
                text: 'Alérgenos (Anexo II)',
                obligatorio: true,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.paper,
                  // Resaltado en rojo cuando se intenta publicar sin
                  // declarar alérgenos ni marcar 'sin alérgenos'.
                  border: Border.all(
                    color: _mostrarErroresBloques &&
                            !_sinAlergenos &&
                            _alergenos.isEmpty
                        ? colors.terracottaDeep
                        : colors.line,
                  ),
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
              if (_mostrarErroresBloques &&
                  !_sinAlergenos &&
                  _alergenos.isEmpty)
                const ErrorInline(
                  text:
                      'Marca los alérgenos del Anexo II o activa "Sin alérgenos".',
                ),
              const SizedBox(height: 24),
              const LabelSeccion(
                text: 'Punto de recogida',
                obligatorio: true,
              ),
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
                text: textoCta,
                fullWidth: true,
                icon: iconoCta,
                onPressed: (cargando || bloqueado) ? null : _guardar,
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

}

/// Grid 3 columnas con miniaturas de las imagenes seleccionadas y un slot
/// "+" al final para añadir hasta `maxImagenes`. La primera miniatura lleva
/// el badge "Portada". El boton ✕ sobre cada thumb la elimina.
class _GridImagenes extends StatelessWidget {
  final List<ImagenSeleccionada> imagenes;
  final int maxImagenes;
  final bool deshabilitado;
  final Future<void> Function() onAnadir;
  final void Function(int index) onQuitar;

  const _GridImagenes({
    required this.imagenes,
    required this.maxImagenes,
    required this.deshabilitado,
    required this.onAnadir,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final puedeAnadir = imagenes.length < maxImagenes;

    // Wrap en lugar de GridView: con 1-2 fotos ocupa solo una fila y la
    // siguiente sección sube; con 4-5 fotos crece a dos filas. Calculamos
    // el lado del tile a partir del ancho real para mantener 3 columnas.
    return LayoutBuilder(
      builder: (context, constraints) {
        const espacio = 8.0;
        final lado = (constraints.maxWidth - espacio * 2) / 3;

        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (var i = 0; i < imagenes.length; i++)
              SizedBox(
                width: lado,
                height: lado,
                child: _ThumbImagen(
                  imagen: imagenes[i],
                  esPortada: i == 0,
                  deshabilitado: deshabilitado,
                  onQuitar: () => onQuitar(i),
                ),
              ),
            if (puedeAnadir)
              SizedBox(
                width: lado,
                height: lado,
                child: _SlotAnadirImagen(
                  deshabilitado: deshabilitado,
                  onTap: onAnadir,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThumbImagen extends StatelessWidget {
  final ImagenSeleccionada imagen;
  final bool esPortada;
  final bool deshabilitado;
  final VoidCallback onQuitar;

  const _ThumbImagen({
    required this.imagen,
    required this.esPortada,
    required this.deshabilitado,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    // Existentes: vienen de Storage, las pintamos con Image.network. Nuevas:
    // bytes en memoria todavía sin subir, Image.memory.
    final Widget contenido = imagen.esExistente
        ? Image.network(
            imagen.urlRemota!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: colors.cream2),
          )
        : Image.memory(imagen.bytes, fit: BoxFit.cover);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: contenido,
        ),
        if (esPortada)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.ink.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Portada',
                style: TextStyle(
                  color: colors.paper,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: deshabilitado ? null : onQuitar,
              customBorder: const CircleBorder(),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.paper.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.close_rounded, size: 14, color: colors.ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotAnadirImagen extends StatelessWidget {
  final bool deshabilitado;
  final Future<void> Function() onTap;

  const _SlotAnadirImagen({required this.deshabilitado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: deshabilitado ? null : onTap,
      child: DottedBorderRect(
        color: colors.line,
        borderRadius: 14,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 22, color: colors.inkSoft),
              const SizedBox(height: 4),
              Text(
                'Añadir',
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenedor con borde discontinuo. Implementacion sencilla para no
/// introducir dependencia externa solo por el slot de añadir foto.
class DottedBorderRect extends StatelessWidget {
  final Color color;
  final double borderRadius;
  final Widget child;

  const DottedBorderRect({
    super.key,
    required this.color,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color, width: 1.4),
      ),
      child: child,
    );
  }
}

// LabelSeccion y ErrorInline viven ahora en
// `lib/core/widgets/ui/label_seccion.dart` para reutilizarse desde otras
// pantallas de formulario (como editar perfil).

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

/// Aviso amarillo que se pinta arriba del formulario en modo edición cuando
/// el plato tiene actividad activa (solicitudes pendientes o transacciones
/// en curso). Comunica que los cambios afectan solo a futuras solicitudes.
class _BannerActividadActiva extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.mustard.withValues(alpha: 0.18),
        border: Border.all(color: colors.mustard.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colors.terracottaDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este plato tiene pedidos en curso. Tus cambios solo afectan a '
              'futuras solicitudes; las que ya están abiertas mantienen los '
              'términos originales.',
              style: TextStyle(
                color: colors.ink,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
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
