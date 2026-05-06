import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/location/ubicacion_actual_provider.dart';
import '../../../core/providers_refresher.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/selector_ubicacion_mapa.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
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
    ref.refrescarUbicacionActual();
    final ubicacionActual = await ref.read(ubicacionActualProvider.future);
    if (!mounted) return;

    if (ubicacionActual != null) {
      final punto = LatLng(ubicacionActual.latitud, ubicacionActual.longitud);
      setState(() => _ubicacionElegida = punto);
      _mapController.move(punto, _zoomMapa);
    } else {
      mostrarError(
          context, Exception('No se pudo obtener la ubicación actual.'));
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
      mostrarExito(context, 'Ubicación actualizada correctamente');
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
    final gpsFallido = !gpsResolviendo && ubicacionActualAsync.value == null;
    final colors = context.yumColors;

    if (!_inicializado && usuario != null) {
      final ubicacionPerfil = usuario.ubicacionPredeterminada;
      final gps = ubicacionActualAsync.value;
      final puedeInicializar =
          ubicacionPerfil != null || !ubicacionActualAsync.isLoading;

      if (puedeInicializar) {
        _inicializado = true;

        final puntoInicial = ubicacionPerfil ??
            (gps == null ? null : LatLng(gps.latitud, gps.longitud));

        _ubicacionElegida = puntoInicial;

        if (puntoInicial != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mapController.move(puntoInicial, _zoomMapa);
          });
        }
      }
    }

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Editar ubicación',
        mostrarBotonVolver: true,
        mostrarBotonPerfil: false,
      ),
      body: YumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectorUbicacionMapa(
                mapController: _mapController,
                ubicacionElegida: _ubicacionElegida,
                ubicacionUsuario: ubicacionActualAsync.value,
                gpsResolviendo: gpsResolviendo,
                gpsFallido: gpsFallido,
                onTap: _guardando ? null : _seleccionarUbicacion,
                titulo: 'Ubicación predeterminada',
                subtitulo:
                    'Toca el mapa para fijar tu ubicación habitual. Será la predeterminada al publicar platos.',
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _guardando ? null : _usarUbicacionActual,
                  icon: Icon(Icons.my_location, size: 18, color: colors.terracotta),
                  label: Text(
                    'Usar mi ubicación actual',
                    style: TextStyle(
                      color: colors.terracotta,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              YumButton(
                text: _guardando ? 'Guardando…' : 'Guardar',
                fullWidth: true,
                onPressed: (_guardando || _ubicacionElegida == null)
                    ? null
                    : _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
