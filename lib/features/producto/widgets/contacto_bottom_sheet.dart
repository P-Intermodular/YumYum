import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/estados_app.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/yum_colors.dart';
import '../../../core/widgets/ui/yum_button.dart';
import '../controllers/contacto_producto_controller.dart';
import '../domain/entities/producto_model.dart';

/// Abre el bottom sheet para iniciar una solicitud de venta o un trueque.
///
/// Devuelve el id de la conversación creada si la solicitud se mandó, o
/// `null` si el usuario cierra la hoja sin completar.
Future<String?> mostrarContactoBottomSheet(
  BuildContext context, {
  required ProductoModel producto,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ContactoSheet(producto: producto),
  );
}

class _ContactoSheet extends ConsumerStatefulWidget {
  final ProductoModel producto;

  const _ContactoSheet({required this.producto});

  @override
  ConsumerState<_ContactoSheet> createState() => _ContactoSheetState();
}

class _ContactoSheetState extends ConsumerState<_ContactoSheet> {
  int _cantidad = 1;
  int _cantidadOfrecida = 1;
  ProductoModel? _productoOfrecido;
  List<ProductoModel>? _candidatos;
  bool _cargandoCandidatos = false;
  bool _enviando = false;

  bool get _esIntercambio =>
      widget.producto.tipo == TipoOferta.intercambio;

  @override
  void initState() {
    super.initState();
    if (_esIntercambio) {
      _cargarCandidatos();
    }
  }

  Future<void> _cargarCandidatos() async {
    setState(() => _cargandoCandidatos = true);
    try {
      final lista = await ref
          .read(contactoProductoControllerProvider.notifier)
          .obtenerProductosIntercambioDisponibles(widget.producto);
      if (!mounted) return;
      setState(() {
        _candidatos = lista;
        _cargandoCandidatos = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _candidatos = const [];
        _cargandoCandidatos = false;
      });
      mostrarError(context, error);
    }
  }

  Future<void> _enviar() async {
    if (_esIntercambio && _productoOfrecido == null) {
      mostrarError(
        context,
        Exception('Elige un plato propio para ofrecer.'),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final conversacionId = await ref
          .read(contactoProductoControllerProvider.notifier)
          .crearSolicitud(
            producto: widget.producto,
            productoOfrecidoId: _productoOfrecido?.id,
            cantidad: _cantidad,
            cantidadOfrecida: _esIntercambio ? _cantidadOfrecida : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(conversacionId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final producto = widget.producto;
    final disponibles = producto.racionesDisponibles;
    final esIntercambio = _esIntercambio;
    final productoOfrecido = _productoOfrecido;
    final maxOfrecido = productoOfrecido?.racionesDisponibles ?? 1;
    final precioUnit = producto.precio ?? 0;
    final total = precioUnit * _cantidad;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                esIntercambio
                    ? 'Proponer trueque'
                    : 'Solicitar a ${producto.propietario.nombre}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      color: colors.ink,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                producto.titulo,
                style: TextStyle(
                  color: colors.inkSoft,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              // Selector de cantidad solicitada (siempre)
              _SeccionLabel(
                texto: esIntercambio
                    ? '¿Cuántas raciones quieres?'
                    : 'Cantidad',
                valorMaximo: disponibles,
              ),
              const SizedBox(height: 8),
              _StepperCantidad(
                valor: _cantidad,
                min: 1,
                max: disponibles,
                onChanged: (v) => setState(() => _cantidad = v),
              ),

              // Total si es venta
              if (!esIntercambio) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.cream2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: colors.inkSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${total.toStringAsFixed(2)} €',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              color: colors.terracottaDeep,
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              // Sección intercambio: lista candidatos + cantidad ofrecida
              if (esIntercambio) ...[
                const SizedBox(height: 18),
                const _SeccionLabel(
                  texto: '¿Qué plato ofreces a cambio?',
                  valorMaximo: null,
                ),
                const SizedBox(height: 8),
                _ListaCandidatos(
                  cargando: _cargandoCandidatos,
                  candidatos: _candidatos ?? const [],
                  seleccionado: productoOfrecido,
                  onSeleccionar: (p) {
                    setState(() {
                      _productoOfrecido = p;
                      _cantidadOfrecida =
                          _cantidadOfrecida.clamp(1, p.racionesDisponibles);
                    });
                  },
                ),
                if (productoOfrecido != null) ...[
                  const SizedBox(height: 14),
                  _SeccionLabel(
                    texto:
                        '¿Cuántas raciones de tu ${productoOfrecido.titulo} entregas?',
                    valorMaximo: maxOfrecido,
                  ),
                  const SizedBox(height: 8),
                  _StepperCantidad(
                    valor: _cantidadOfrecida.clamp(1, maxOfrecido),
                    min: 1,
                    max: maxOfrecido,
                    onChanged: (v) => setState(() => _cantidadOfrecida = v),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              YumButton(
                text: _enviando
                    ? 'Enviando…'
                    : (esIntercambio ? 'Proponer trueque' : 'Solicitar'),
                fullWidth: true,
                onPressed: _enviando ? null : _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeccionLabel extends StatelessWidget {
  final String texto;
  final int? valorMaximo;

  const _SeccionLabel({required this.texto, this.valorMaximo});

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: colors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (valorMaximo != null)
          Text(
            'máx. $valorMaximo',
            style: TextStyle(color: colors.inkSoft, fontSize: 11),
          ),
      ],
    );
  }
}

class _StepperCantidad extends StatelessWidget {
  final int valor;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperCantidad({
    required this.valor,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    final puedeBajar = valor > min;
    final puedeSubir = valor < max;
    return Row(
      children: [
        _BotonStep(
          icon: Icons.remove_rounded,
          activo: puedeBajar,
          onTap: () => puedeBajar ? onChanged(valor - 1) : null,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.paper,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              valor.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    color: colors.ink,
                  ),
            ),
          ),
        ),
        _BotonStep(
          icon: Icons.add_rounded,
          activo: puedeSubir,
          onTap: () => puedeSubir ? onChanged(valor + 1) : null,
        ),
      ],
    );
  }
}

class _BotonStep extends StatelessWidget {
  final IconData icon;
  final bool activo;
  final VoidCallback? onTap;

  const _BotonStep({
    required this.icon,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: activo ? colors.terracotta : colors.cream2,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: activo ? colors.paper : colors.inkSoft,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ListaCandidatos extends StatelessWidget {
  final bool cargando;
  final List<ProductoModel> candidatos;
  final ProductoModel? seleccionado;
  final ValueChanged<ProductoModel> onSeleccionar;

  const _ListaCandidatos({
    required this.cargando,
    required this.candidatos,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.yumColors;
    if (cargando) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: colors.terracotta),
        ),
      );
    }
    if (candidatos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.mustard.withValues(alpha: 0.18),
          border: Border.all(color: colors.mustard.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Necesitas tener algún plato publicado como intercambio para poder ofrecerlo.',
          style: TextStyle(color: colors.ink, fontSize: 13, height: 1.4),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: candidatos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = candidatos[index];
          final activo = seleccionado?.id == c.id;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSeleccionar(c),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activo
                    ? colors.terracotta.withValues(alpha: 0.10)
                    : colors.paper,
                border: Border.all(
                  color: activo ? colors.terracotta : colors.line,
                  width: activo ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.network(
                        c.urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: colors.cream2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.racionesDisponibles} de ${c.racionesTotales} raciones',
                          style: TextStyle(
                            color: colors.inkSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activo)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.terracotta,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
