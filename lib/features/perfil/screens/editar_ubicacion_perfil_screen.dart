import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/widgets/selector_ubicacion_mapa.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';

/// Pantalla para editar la ubicación predeterminada del perfil.
class EditarUbicacionPerfilScreen extends ConsumerStatefulWidget {
  const EditarUbicacionPerfilScreen({super.key});

  @override
  ConsumerState<EditarUbicacionPerfilScreen> createState() =>
      _EditarUbicacionPerfilScreenState();
}

class _EditarUbicacionPerfilScreenState
    extends ConsumerState<EditarUbicacionPerfilScreen> {
  static const double _zoomMapa = 16;

  final _mapController = MapController();
  LatLng? _ubicacionElegida;
  bool _inicializado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _seleccionarUbicacion(LatLng punto) {
    setState(() => _ubicacionElegida = punto);
  }

  Future<void> _usarUbicacionActual() async {
    final ubicacionActual = await ref.read(ubicacionActualProvider.future);
    if (!mounted) return;

    if (ubicacionActual != null) {
      final punto = LatLng(ubicacionActual.latitud, ubicacionActual.longitud);
      setState(() => _ubicacionElegida = punto);
      _mapController.move(punto, _zoomMapa);
    } else {
      mostrarError(context, Exception('No se pudo obtener la ubicacion actual.'));
    }
  }

  Future<void> _guardar() async {
    if (_ubicacionElegida == null) return;

    final usuario = ref.read(autenticacionProvider).value;
    if (usuario == null) return;

    setState(() => _guardando = true);
    try {
      final usuarioActualizado = usuario.copyWith(
        latitudPredeterminada: _ubicacionElegida!.latitude,
        longitudPredeterminada: _ubicacionElegida!.longitude,
      );

      await ref
          .read(autenticacionProvider.notifier)
          .actualizarUbicacionPredeterminada(usuarioActualizado);

      if (!mounted) return;
      context.pop();
      mostrarExito(context, 'Ubicacion actualizada correctamente');
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(autenticacionProvider).value;
    final ubicacionActualAsync = ref.watch(ubicacionActualProvider);
    final gpsResolviendo = ubicacionActualAsync.isLoading;
    final gpsFallido =
        !gpsResolviendo && ubicacionActualAsync.valueOrNull == null;

    if (!_inicializado && usuario != null) {
      _inicializado = true;
      _ubicacionElegida = usuario.ubicacionPredeterminada;
      if (_ubicacionElegida != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(_ubicacionElegida!, _zoomMapa);
        });
      } else {
        final gps = ubicacionActualAsync.valueOrNull;
        if (gps != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mapController.move(
              LatLng(gps.latitud, gps.longitud),
              _zoomMapa,
            );
          });
        }
      }
    }

    return Scaffold(
      appBar: const YumYumAppBar(titulo: 'Editar ubicacion'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectorUbicacionMapa(
              mapController: _mapController,
              ubicacionElegida: _ubicacionElegida,
              ubicacionUsuario: ubicacionActualAsync.valueOrNull,
              gpsResolviendo: gpsResolviendo,
              gpsFallido: gpsFallido,
              onTap: _guardando ? null : _seleccionarUbicacion,
              titulo: 'Ubicacion predeterminada',
              subtitulo: 'Toca el mapa para establecer tu ubicacion habitual. '
                  'Sera la predeterminada al publicar platos.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _guardando ? null : _usarUbicacionActual,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Usar mi ubicacion actual'),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_guardando || _ubicacionElegida == null)
                  ? null
                  : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
