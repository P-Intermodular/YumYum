import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/yumyum_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../pedidos/domain/entities/transaccion_model.dart';
import '../../pedidos/providers/transaccion_providers.dart';
import '../controllers/valoracion_controller.dart';
import '../providers/valoracion_providers.dart';

/// Pantalla para valorar a la contraparte de una transacción completada.
class ValorarTransaccionScreen extends ConsumerStatefulWidget {
  final String transaccionId;

  const ValorarTransaccionScreen({super.key, required this.transaccionId});

  @override
  ConsumerState<ValorarTransaccionScreen> createState() =>
      _ValorarTransaccionScreenState();
}

class _ValorarTransaccionScreenState
    extends ConsumerState<ValorarTransaccionScreen> {
  int _puntuacion = 0;
  final _comentarioController = TextEditingController();

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarValoracion() async {
    if (_puntuacion == 0) {
      mostrarError(context, Exception('Selecciona al menos una estrella.'));
      return;
    }

    final transaccion =
        ref.read(transaccionDetalleProvider(widget.transaccionId)).value;
    if (transaccion == null) return;

    try {
      await ref.read(valoracionControllerProvider.notifier).enviarValoracion(
            transaccion: transaccion,
            puntuacion: _puntuacion,
            comentario: _comentarioController.text.trim().isEmpty
                ? null
                : _comentarioController.text.trim(),
          );

      if (mounted) {
        mostrarExito(context, 'Valoracion enviada');
        context.go(RutasApp.pedidos);
      }
    } catch (error) {
      if (mounted) {
        mostrarError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaccionAsync =
        ref.watch(transaccionDetalleProvider(widget.transaccionId));
    final usuario = ref.watch(autenticacionProvider).value;
    final cargando = ref.watch(valoracionControllerProvider).isLoading;

    return Scaffold(
      appBar: const YumYumAppBar(
        titulo: 'Valorar',
        mostrarBotonVolver: true,
      ),
      body: transaccionAsync.when(
        data: (transaccion) {
          if (transaccion == null || usuario == null) {
            return const Center(child: Text('Transaccion no encontrada'));
          }

          final valoracionAsync = ref.watch(
            valoracionUsuarioProvider((transaccion.id, usuario.id)),
          );

          return valoracionAsync.when(
            data: (valoracionExistente) {
              if (valoracionExistente != null) {
                return _VistaValoracionExistente(
                  nombreContraparte: transaccion.nombreContraparte,
                  urlAvatar: transaccion.urlAvatarContraparte,
                  idContraparte: transaccion.contraparte(usuario.id),
                  puntuacion: valoracionExistente.puntuacion,
                  comentario: valoracionExistente.comentario,
                );
              }

              return _buildFormulario(transaccion, usuario.id, cargando);
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text(mensajeError(e))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(mensajeError(e))),
      ),
    );
  }

  Widget _buildFormulario(
    TransaccionModel transaccion,
    String usuarioId,
    bool cargando,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AvatarUsuario(
            nombre: transaccion.nombreContraparte,
            identificadorColor: transaccion.contraparte(usuarioId),
            urlImagen: transaccion.urlAvatarContraparte,
            radius: 40,
          ),
          const SizedBox(height: 12),
          Text(
            transaccion.nombreContraparte,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4A5B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            transaccion.tituloProducto,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32),
          const Text(
            'Como fue tu experiencia?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F4A5B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final estrella = index + 1;
              return IconButton(
                onPressed: cargando
                    ? null
                    : () => setState(() => _puntuacion = estrella),
                icon: Icon(
                  estrella <= _puntuacion
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 40,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _comentarioController,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            enabled: !cargando,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (cargando || _puntuacion == 0)
                  ? null
                  : _enviarValoracion,
              child: cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Enviar valoracion'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra una valoración ya enviada en modo lectura.
class _VistaValoracionExistente extends StatelessWidget {
  final String nombreContraparte;
  final String urlAvatar;
  final String idContraparte;
  final int puntuacion;
  final String? comentario;

  const _VistaValoracionExistente({
    required this.nombreContraparte,
    required this.urlAvatar,
    required this.idContraparte,
    required this.puntuacion,
    this.comentario,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AvatarUsuario(
            nombre: nombreContraparte,
            identificadorColor: idContraparte,
            urlImagen: urlAvatar,
            radius: 40,
          ),
          const SizedBox(height: 12),
          Text(
            nombreContraparte,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F4A5B),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Tu valoracion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F4A5B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < puntuacion
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 40,
                color: Colors.amber,
              );
            }),
          ),
          if (comentario != null && comentario!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comentario!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Valoracion enviada',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
