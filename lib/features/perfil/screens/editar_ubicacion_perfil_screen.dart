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
import '../../../core/widgets/ui/yum_app_bar.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../auth/controllers/auth_controller.dart';

/// Pantalla para editar la ubicación predeterminada del perfil.
///
/// Subpantalla del flujo de Ajustes — sigue el patrón Figma de TopBar
/// compacta (`<TopBar title subtitle back />`) con el mapa y el banner de
/// privacidad debajo.
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

  void _actualizarPunto(LatLng punto) {
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
      if (mounted) mostrarError(context, error);
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
      appBar: const YumAppBar(
        title: 'Editar ubicación',
        subtitle: 'Define tu zona predeterminada',
        showBack: true,
      ),
      backgroundColor: colors.cream,
      body: YumBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 28,
            ),
            children: [
              SelectorUbicacionMapa(
                mapController: _mapController,
                ubicacionElegida: _ubicacionElegida,
                ubicacionUsuario: ubicacionActualAsync.value,
                gpsResolviendo: gpsResolviendo,
                gpsFallido: gpsFallido,
                onPuntoCambiado: _guardando ? null : _actualizarPunto,
                onUsarUbicacionActual:
                    _guardando ? null : _usarUbicacionActual,
                subtitulo: 'Arrastra el mapa para fijar tu zona habitual.',
                altura: 380,
              ),
              const SizedBox(height: 16),
              _BannerPrivacidad(),
              const SizedBox(height: 28),
              YumButton(
                text: _guardando ? 'Guardando…' : 'Guardar ubicación',
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

/// Banner olive con el copy de privacidad. Refuerza la confianza del
/// usuario al pedirle la ubicación: explica qué guardamos y qué no.
class _BannerPrivacidad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.olive.withValues(alpha: 0.10),
        border: Border.all(color: colors.olive.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: colors.oliveDeep,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Solo guardamos esta zona como referencia. Tu dirección exacta '
              'únicamente se comparte al confirmar un pedido.',
              style: TextStyle(
                color: colors.oliveDeep,
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
