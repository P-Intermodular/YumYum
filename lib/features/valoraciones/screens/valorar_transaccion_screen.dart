import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/constants/rutas_app.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/avatar_usuario.dart';
import '../../../core/widgets/ui/yum_background.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../../../core/widgets/ui/yum_card.dart';
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
        mostrarExito(context, 'Valoración enviada');
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
        mostrarBotonPerfil: false,
      ),
      body: YumBackground(
        child: transaccionAsync.when(
          data: (transaccion) {
            if (transaccion == null || usuario == null) {
              return _buildMensajeCentrado('Transacción no encontrada');
            }

            if (transaccion.estado != EstadoTransaccion.completada) {
              return _buildBloqueoValoracion();
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildMensajeCentrado(mensajeError(e)),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildMensajeCentrado(mensajeError(e)),
        ),
      ),
    );
  }

  Widget _buildMensajeCentrado(String texto) {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.inkSoft),
        ),
      ),
    );
  }

  Widget _buildBloqueoValoracion() {
    final colors = context.yumColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: YumCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 40,
                color: colors.terracottaDeep,
              ),
              const SizedBox(height: 14),
              Text(
                'Aún no se puede valorar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      color: colors.ink,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Solo podrás enviar una valoración cuando la transacción figure como completada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.inkSoft, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              YumButton(
                text: 'Volver a pedidos',
                fullWidth: true,
                onPressed: () => context.go(RutasApp.pedidos),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario(
    TransaccionModel transaccion,
    String usuarioId,
    bool cargando,
  ) {
    final colors = context.yumColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  color: colors.ink,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            transaccion.tituloProducto,
            style: TextStyle(color: colors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 32),
          Text(
            '¿Cómo fue tu experiencia?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _SelectorEstrellas(
            valor: _puntuacion,
            onChanged: cargando ? null : (v) => setState(() => _puntuacion = v),
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
          const SizedBox(height: 28),
          YumButton(
            text: cargando ? 'Enviando…' : 'Enviar valoración',
            fullWidth: true,
            onPressed: (cargando || _puntuacion == 0) ? null : _enviarValoracion,
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
    final colors = context.yumColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  color: colors.ink,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu valoración',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _SelectorEstrellas(valor: puntuacion, onChanged: null),
          if (comentario != null && comentario!.isNotEmpty) ...[
            const SizedBox(height: 24),
            YumCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                comentario!,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.ink,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _ChipExito(texto: 'Valoración enviada'),
        ],
      ),
    );
  }
}

/// Selector de 5 estrellas con tinte mustard.
class _SelectorEstrellas extends StatelessWidget {
  final int valor;
  final ValueChanged<int>? onChanged;

  const _SelectorEstrellas({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final desactivado = onChanged == null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final estrella = index + 1;
        final activa = estrella <= valor;
        return IconButton(
          onPressed: desactivado ? null : () => onChanged!(estrella),
          icon: Icon(
            activa ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 38,
            color: activa ? colors.mustard : colors.inkSoft,
          ),
        );
      }),
    );
  }
}

/// Pill de éxito con tinte olive (alineado con la marca).
class _ChipExito extends StatelessWidget {
  final String texto;

  const _ChipExito({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.olive.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: colors.oliveDeep,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: colors.oliveDeep,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
