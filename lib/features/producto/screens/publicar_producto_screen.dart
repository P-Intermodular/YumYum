import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/widgets/selector_ubicacion_mapa.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/datos_publicacion_producto.dart';
import '../controllers/publicar_producto_controller.dart';

/// Pantalla de creación de nuevas ofertas.
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
  final _picker = ImagePicker();
  final _mapController = MapController();

  Uint8List? _bytesImagen;
  String _extensionImagen = 'jpg';
  String _tipo = TipoOferta.intercambio;
  LatLng? _ubicacionElegida;
  bool _mapaCentradoEnPerfil = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Abre la galería y guarda la imagen elegida en memoria.
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

  /// Valida el formulario y publica la oferta en el backend.
  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    final ubicacion = _ubicacionElegida;
    if (ubicacion == null) {
      mostrarError(
        context,
        Exception('Configura tu ubicacion en el perfil antes de publicar.'),
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
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  /// Reacciona al tap del usuario sobre el mapa fijando el punto exacto.
  void _seleccionarUbicacion(LatLng punto) {
    setState(() => _ubicacionElegida = punto);
  }

  /// Establece la ubicacion elegida a la ubicacion actual del GPS.
  Future<void> _usarUbicacionActual() async {
    final ubicacionActual = await ref.read(ubicacionActualProvider.future);
    if (!mounted) return;

    if (ubicacionActual != null) {
      final punto = LatLng(ubicacionActual.latitud, ubicacionActual.longitud);
      setState(() => _ubicacionElegida = punto);
      _mapController.move(punto, _zoomMapa);
    } else {
      mostrarError(
        context,
        Exception('No se pudo obtener la ubicacion actual.'),
      );
    }
  }

  /// Restablece la ubicación elegida a la del perfil.
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

    if (ubicacionPerfil != null && !_mapaCentradoEnPerfil) {
      _mapaCentradoEnPerfil = true;
      _ubicacionElegida ??= ubicacionPerfil;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(ubicacionPerfil, _zoomMapa);
      });
    }

    final bool ubicacionDifiereDePerfil = _ubicacionElegida != null &&
        ubicacionPerfil != null &&
        (_ubicacionElegida!.latitude != ubicacionPerfil.latitude ||
            _ubicacionElegida!.longitude != ubicacionPerfil.longitude);

    return Scaffold(
      appBar: const YumYumAppBar(titulo: 'Publicar'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: cargando ? null : _elegirImagen,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _bytesImagen == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Toca para anadir foto',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : Image.memory(_bytesImagen!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tituloController,
                decoration:
                    const InputDecoration(labelText: 'Titulo de la oferta'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripcion'),
                maxLines: 4,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de oferta'),
                items: const [
                  DropdownMenuItem(
                      value: TipoOferta.intercambio,
                      child: Text('Intercambio')),
                  DropdownMenuItem(
                      value: TipoOferta.venta, child: Text('Venta')),
                ],
                onChanged: (val) => setState(() => _tipo = val!),
              ),
              if (_tipo == TipoOferta.venta) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (_tipo != TipoOferta.venta) return null;
                    final parsed =
                        double.tryParse((val ?? '').replaceAll(',', '.'));
                    return parsed == null ? 'Introduce un precio valido' : null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              if (bloqueado)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade800, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Configura tu ubicacion predeterminada en el perfil antes de publicar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push(RutasApp.perfilUbicacion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade900,
                          elevation: 0,
                        ),
                        child: const Text('Configurar ahora'),
                      ),
                    ],
                  ),
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
                  subtitulo: 'Usando tu ubicacion predeterminada. '
                      'Toca el mapa para ajustarla solo para este plato.',
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: cargando ? null : _usarUbicacionActual,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Usar mi ubicacion actual'),
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (cargando || bloqueado) ? null : _publicar,
                child: cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Publicar oferta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
