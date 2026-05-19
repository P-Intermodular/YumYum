import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../constants/rutas_app.dart';
import '../../location/ubicacion_actual_provider.dart';
import '../../services/ia_service.dart';
import '../../theme/yum_colors.dart';

/// FAB persistente del asistente IA. Se monta en el shell autenticado
/// (`PrincipalScreen`) y abre un bottom sheet conversacional multi-turno.
/// La integracion con Gemini (function calling, busqueda real de productos
/// cercanos via RPC y contexto del perfil) vive en la Edge Function
/// `asistente-ia` de Supabase; el cliente solo orquesta historial e
/// interaccion.
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
      builder: (sheetContext) => const _AsistenteSheet(),
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

/// Sugerencias iniciales mostradas solo cuando no hay turnos previos.
const List<String> _sugerenciasIniciales = [
  '¿Qué hay para comer cerca?',
  'Quiero algo dulce',
  'Planifica mi comida de hoy',
  'Ayúdame a publicar un plato',
];

/// Mensajes rotatorios mientras la IA esta razonando, para que el
/// loading no parezca colgado.
const List<String> _mensajesLoading = [
  'Pensando…',
  'Buscando platos cerca de ti…',
  'Cruzando tus preferencias…',
  'Casi listo…',
];

/// Turno renderizable en el chat. Mezcla turnos de usuario (solo texto) y
/// turnos del asistente (texto + posibles productos / prefilled).
sealed class _Turno {
  const _Turno();
}

class _TurnoUsuario extends _Turno {
  final String texto;
  const _TurnoUsuario(this.texto);
}

class _TurnoAsistente extends _Turno {
  final RespuestaAsistente respuesta;
  final bool esUltimo;
  const _TurnoAsistente(this.respuesta, {required this.esUltimo});
}

/// Bottom sheet conversacional multi-turno. Usa
/// `DraggableScrollableSheet` para ocupar la mayor parte de la pantalla y
/// dejar espacio para la conversacion completa.
class _AsistenteSheet extends ConsumerStatefulWidget {
  const _AsistenteSheet();

  @override
  ConsumerState<_AsistenteSheet> createState() => _AsistenteSheetState();
}

class _AsistenteSheetState extends ConsumerState<_AsistenteSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MensajeChat> _historial = [];
  final List<_Turno> _turnos = [];
  bool _cargando = false;
  String? _error;

  Future<void> _enviarConTexto(String texto) async {
    final preparado = texto.trim();
    if (preparado.isEmpty) return;
    _controller.text = preparado;
    await _enviar();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final usuario = ref.read(autenticacionProvider).valueOrNull;
    if (usuario == null) {
      setState(() => _error = 'Inicia sesion para usar el asistente.');
      return;
    }

    final mensajeUsuario = MensajeChat(rol: RolMensaje.user, texto: texto);

    setState(() {
      _historial.add(mensajeUsuario);
      _turnos.add(_TurnoUsuario(texto));
      _cargando = true;
      _error = null;
      _controller.clear();
    });
    _scrollAlFinal();

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
      final respuesta = await IAService.enviarHistorial(
        _historial,
        latitud: lat,
        longitud: lon,
      );
      if (!mounted) return;
      setState(() {
        _historial.add(
          MensajeChat(rol: RolMensaje.assistant, texto: respuesta.respuesta),
        );
        // Reetiquetamos el turno anterior del asistente para que pierda
        // los chips de accion: solo el ultimo turno responde a "publicar".
        for (var i = 0; i < _turnos.length; i++) {
          final t = _turnos[i];
          if (t is _TurnoAsistente && t.esUltimo) {
            _turnos[i] = _TurnoAsistente(t.respuesta, esUltimo: false);
          }
        }
        _turnos.add(_TurnoAsistente(respuesta, esUltimo: true));
        _cargando = false;
      });
      _scrollAlFinal();
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
      _historial.clear();
      _turnos.clear();
      _error = null;
      _controller.clear();
    });
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _irAProducto(String productoId) {
    Navigator.pop(context);
    context.push(RutasApp.productoDetalle(productoId));
  }

  void _irAPublicar() {
    Navigator.pop(context);
    context.go(RutasApp.publicar);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollSheetController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const _ManijaDrag(),
              _Cabecera(
                puedeReiniciar: _turnos.isNotEmpty || _cargando,
                onReiniciar: _reiniciar,
              ),
              const Divider(height: 1),
              Expanded(
                child: _turnos.isEmpty && !_cargando
                    ? _VistaBienvenida(onSugerencia: _enviarConTexto)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _turnos.length + (_cargando ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (index == _turnos.length) {
                            return const _BurbujaLoading();
                          }
                          final turno = _turnos[index];
                          if (turno is _TurnoUsuario) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BurbujaUsuario(texto: turno.texto),
                            );
                          }
                          turno as _TurnoAsistente;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _BurbujaAsistente(
                              respuesta: turno.respuesta,
                              acciones: turno.esUltimo,
                              onProducto: _irAProducto,
                              onPublicar: _irAPublicar,
                            ),
                          );
                        },
                      ),
              ),
              if (_error != null) _BannerError(error: _error!),
              SafeArea(
                top: false,
                child: _BarraInput(
                  controller: _controller,
                  habilitado: !_cargando,
                  onEnviar: _enviar,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ManijaDrag extends StatelessWidget {
  const _ManijaDrag();

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.olive.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final bool puedeReiniciar;
  final VoidCallback onReiniciar;
  const _Cabecera({required this.puedeReiniciar, required this.onReiniciar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: context.yumColors.terracotta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Asistente YumYum',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (puedeReiniciar)
            IconButton(
              tooltip: 'Nueva conversación',
              onPressed: onReiniciar,
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _VistaBienvenida extends StatelessWidget {
  final void Function(String texto) onSugerencia;
  const _VistaBienvenida({required this.onSugerencia});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Cuéntame qué te apetece o qué quieres hacer.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Puedo recomendarte platos cercanos, planificar comidas o ayudarte a publicar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text(
            'Prueba con:',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sugerencia in _sugerenciasIniciales)
                ActionChip(
                  avatar: Icon(Icons.bolt_rounded,
                      size: 16, color: colors.oliveDeep),
                  label: Text(sugerencia),
                  onPressed: () => onSugerencia(sugerencia),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BurbujaUsuario extends StatelessWidget {
  final String texto;
  const _BurbujaUsuario({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.terracotta.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _BurbujaAsistente extends StatelessWidget {
  final RespuestaAsistente respuesta;
  final bool acciones;
  final void Function(String productoId) onProducto;
  final VoidCallback onPublicar;

  const _BurbujaAsistente({
    required this.respuesta,
    required this.acciones,
    required this.onProducto,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final tieneProductos = respuesta.productos.isNotEmpty;
    final buscoSinResultados =
        respuesta.accion == AccionAsistente.buscar && !tieneProductos;
    final mostrarBotonPublicar = acciones &&
        (respuesta.accion == AccionAsistente.publicar ||
            respuesta.prefilled != null ||
            buscoSinResultados);
    final etiquetaBotonPublicar = buscoSinResultados
        ? 'Publica tú un plato'
        : 'Empezar a publicar';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.olive.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                respuesta.respuesta,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (tieneProductos) ...[
              const SizedBox(height: 10),
              for (final p in respuesta.productos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ProductoChip(
                    producto: p,
                    onTap: () => onProducto(p.id),
                  ),
                ),
            ] else if (buscoSinResultados && acciones) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.cream2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.olive.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: colors.oliveDeep),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¿Te animas a cocinarlo tú?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (mostrarBotonPublicar) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onPublicar,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(etiquetaBotonPublicar),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Burbuja "el asistente esta escribiendo" con mensajes rotatorios.
class _BurbujaLoading extends StatefulWidget {
  const _BurbujaLoading();

  @override
  State<_BurbujaLoading> createState() => _BurbujaLoadingState();
}

class _BurbujaLoadingState extends State<_BurbujaLoading> {
  int _indice = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        _indice = (_indice + 1) % _mensajesLoading.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.olive.withValues(alpha: 0.25),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.terracotta,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _mensajesLoading[_indice],
                key: ValueKey(_indice),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  final String error;
  const _BannerError({required this.error});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colors.terracotta.withValues(alpha: 0.12),
      child: Text(
        error,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: colors.terracottaDeep),
      ),
    );
  }
}

class _BarraInput extends StatelessWidget {
  final TextEditingController controller;
  final bool habilitado;
  final VoidCallback onEnviar;

  const _BarraInput({
    required this.controller,
    required this.habilitado,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              enabled: habilitado,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onEnviar(),
              decoration: InputDecoration(
                hintText: habilitado
                    ? 'Escribe algo…'
                    : 'Esperando respuesta…',
                filled: true,
                fillColor: colors.cream2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: colors.terracotta,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: habilitado ? onEnviar : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.send_rounded,
                  color: colors.paper,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
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
