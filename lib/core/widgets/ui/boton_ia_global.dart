import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../constants/rutas_app.dart';
import '../../location/ubicacion_actual_provider.dart';
import '../../services/ia_service.dart';
import '../../theme/yum_colors.dart';

/// FAB persistente del asistente IA. Se monta en el shell autenticado
/// (`PrincipalScreen`) y abre un bottom sheet conversacional con tres
/// estados: input -> loading -> respuesta. El bottom sheet llama a
/// [IAService], que invoca la Edge Function `asistente-ia` de Supabase.
/// La integracion con Gemini (con function calling y busqueda real de
/// productos cercanos via RPC) vive en el servidor, no en el cliente.
class BotonIAGlobal extends StatelessWidget {
  const BotonIAGlobal({super.key});

  Future<void> _abrirModal(BuildContext context) async {
    final colors = context.yumColors;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const _AsistenteSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Tooltip(
      message: 'Asistente IA',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.terracotta,
                Color.lerp(colors.terracotta, colors.cream, 0.35)!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.terracotta.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _abrirModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.paper,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet conversacional. Tres estados sucesivos:
/// - Input: campo de texto + boton de envio.
/// - Loading: spinner mientras la Edge Function razona.
/// - Respuesta: texto natural del asistente + chips de accion (productos
///   o publicar) que cierran el sheet y navegan al sitio correspondiente.
class _AsistenteSheet extends ConsumerStatefulWidget {
  const _AsistenteSheet();

  @override
  ConsumerState<_AsistenteSheet> createState() => _AsistenteSheetState();
}

class _AsistenteSheetState extends ConsumerState<_AsistenteSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _cargando = false;
  RespuestaAsistente? _respuesta;
  String? _error;

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final usuario = ref.read(autenticacionProvider).valueOrNull;
    if (usuario == null) {
      setState(() => _error = 'Inicia sesion para usar el asistente.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    // Resolvemos la ubicacion sin bloquear si falla: la IA igual responde,
    // solo que sin productos cercanos cuando los necesite.
    double? lat;
    double? lon;
    try {
      final ubicacion = await ref.read(ubicacionActualProvider.future);
      lat = ubicacion?.latitud;
      lon = ubicacion?.longitud;
    } catch (_) {
      lat = null;
      lon = null;
    }

    try {
      final respuesta = await IAService.procesarTexto(
        texto,
        usuario.id,
        latitud: lat,
        longitud: lon,
      );
      if (!mounted) return;
      setState(() {
        _respuesta = respuesta;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  void _reiniciar() {
    setState(() {
      _respuesta = null;
      _error = null;
      _controller.clear();
    });
  }

  void _irAProducto(BuildContext sheetContext, String productoId) {
    Navigator.pop(sheetContext);
    sheetContext.push(RutasApp.productoDetalle(productoId));
  }

  void _irAPublicar(BuildContext sheetContext) {
    Navigator.pop(sheetContext);
    sheetContext.go(RutasApp.publicar);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cabecera(reiniciar: _respuesta != null ? _reiniciar : null),
            const SizedBox(height: 16),
            if (_respuesta != null)
              _VistaRespuesta(
                respuesta: _respuesta!,
                onProducto: (id) => _irAProducto(context, id),
                onPublicar: () => _irAPublicar(context),
              )
            else
              _VistaInput(
                controller: _controller,
                cargando: _cargando,
                error: _error,
                onEnviar: _enviar,
              ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final VoidCallback? reiniciar;
  const _Cabecera({this.reiniciar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: context.yumColors.terracotta),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Asistente YumYum',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (reiniciar != null)
          TextButton.icon(
            onPressed: reiniciar,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Nueva consulta'),
          ),
      ],
    );
  }
}

class _VistaInput extends StatelessWidget {
  final TextEditingController controller;
  final bool cargando;
  final String? error;
  final VoidCallback onEnviar;

  const _VistaInput({
    required this.controller,
    required this.cargando,
    required this.error,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cuentame que te apetece o que quieres hacer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          enabled: !cargando,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onEnviar(),
          decoration: InputDecoration(
            hintText:
                'Ej: "quiero comerme un kebab", "planifica mi comida de hoy" o "ayudame a publicar un plato"',
            suffixIcon: cargando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: colors.oliveDeep,
                    onPressed: onEnviar,
                  ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.terracottaDeep),
          ),
        ],
      ],
    );
  }
}

class _VistaRespuesta extends StatelessWidget {
  final RespuestaAsistente respuesta;
  final void Function(String productoId) onProducto;
  final VoidCallback onPublicar;

  const _VistaRespuesta({
    required this.respuesta,
    required this.onProducto,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final tieneProductos = respuesta.productos.isNotEmpty;
    final mostrarBotonPublicar =
        respuesta.accion == AccionAsistente.publicar ||
            (respuesta.prefilled != null && !tieneProductos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.olive.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            respuesta.respuesta,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (tieneProductos) ...[
          const SizedBox(height: 16),
          Text(
            'Sugerencias cercanas',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: respuesta.productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final p = respuesta.productos[index];
                return _ProductoChip(
                  producto: p,
                  onTap: () => onProducto(p.id),
                );
              },
            ),
          ),
        ],
        if (mostrarBotonPublicar) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPublicar,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Empezar a publicar'),
          ),
        ],
      ],
    );
  }
}

class _ProductoChip extends StatelessWidget {
  final ProductoSugerido producto;
  final VoidCallback onTap;

  const _ProductoChip({required this.producto, required this.onTap});

  String _distanciaFormateada() {
    final d = producto.distanciaKm;
    if (d == null) return '';
    if (d < 1) return '· ${(d * 1000).round()} m';
    return '· ${d.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final precio = producto.precio;
    final subtitulo = [
      producto.tipo == 'venta'
          ? (precio != null ? 'Venta · $precio€' : 'Venta')
          : 'Intercambio',
      if (producto.propietarioNombre != null) producto.propietarioNombre!,
      _distanciaFormateada(),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Material(
      color: colors.paper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.olive.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: producto.imagenPrincipal != null
                      ? Image.network(
                          producto.imagenPrincipal!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.restaurant_rounded,
                              color: colors.oliveDeep),
                        )
                      : Container(
                          color: colors.olive.withValues(alpha: 0.4),
                          child: Icon(Icons.restaurant_rounded,
                              color: colors.oliveDeep),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.titulo,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.oliveDeep),
            ],
          ),
        ),
      ),
    );
  }
}
