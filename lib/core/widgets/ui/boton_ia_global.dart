import 'package:flutter/material.dart';
import '../../theme/yum_colors.dart';
import '../../services/ia_service.dart';
import '../../router/app_router.dart';

/// Componente global que renderiza el botón flotante de Inteligencia Artificial.
/// Al pulsarse, despliega un modal inferior (BottomSheet) con un formulario
/// para interactuar con el asistente virtual.
class BotonIAGlobal extends StatelessWidget {
  const BotonIAGlobal({super.key});

  /// Despliega el modal de interacción con la IA.
  /// Implementa una estrategia de padding segura para Flutter Web que absorbe
  /// el redimensionamiento del teclado sin provocar excepciones de layout.
  void _abrirModalIA(BuildContext context) {
    final coloresGlobales = context.yumColors;
    final contextoNavegador = rootNavigatorKey.currentContext!;

    showModalBottomSheet(
      context: contextoNavegador,
      isScrollControlled: true, // Requerido para modales que ocupan más de la mitad de la pantalla
      backgroundColor: coloresGlobales.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        // Envolvemos el modal en un Padding que escucha los insets.
        // Al colocarlo en la raíz del builder, Flutter ajusta el lienzo 
        // antes de intentar calcular el tamaño del TextField, evitando el cuelgue.
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: const _FormularioIA(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: FloatingActionButton(
        onPressed: () => _abrirModalIA(context),
        backgroundColor: context.yumColors.mintDeep,
        foregroundColor: context.yumColors.paper,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}

/// Widget privado que encapsula el estado del campo de texto y 
/// la gestión del ciclo de vida de la petición al servidor.
class _FormularioIA extends StatefulWidget {
  const _FormularioIA();

  @override
  State<_FormularioIA> createState() => _FormularioIAState();
}

class _FormularioIAState extends State<_FormularioIA> {
  final TextEditingController _controller = TextEditingController();
  bool _cargando = false;

  /// Extrae el texto, bloquea la interfaz mostrando el indicador de carga,
  /// y delega la ejecución de la lógica de red al servicio correspondiente.
  Future<void> _enviarPeticion() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() => _cargando = true);

    try {
      // Delegación de la petición HTTP. 
      // TODO: Sustituir 'user_123' por el ID del usuario autenticado en Supabase.
      final respuesta = await IAService.procesarTexto(texto, 'user_123');
      
      if (!mounted) return;
      
      // Cierra el BottomSheet una vez la red responde correctamente.
      Navigator.pop(context); 
      
      // Intercepción del intent detectado por la IA para orquestar la navegación.
      if (respuesta['accion'] == 'publicar') {
        debugPrint('Intención: PUBLICAR. Borrador: ${respuesta['borrador']}');
        // TODO: Inyectar datos en el Provider y redirigir a RutasApp.publicar
      } else if (respuesta['accion'] == 'buscar') {
        debugPrint('Intención: BUSCAR. Resultados: ${respuesta['resultados']}');
        // TODO: Actualizar el listado del feed con los resultados obtenidos
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Al usar SafeArea evitamos que el modal se pegue a los bordes
    // físicos del dispositivo cuando el teclado no está abierto.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          // mainAxisSize.min asegura que el modal solo ocupe lo que necesita su contenido,
          // previniendo que se expanda infinitamente y colapse el layout de la Web.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Qué necesitas hacer hoy?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              // Eliminado autofocus en Web para evitar que se lance el teclado 
              // antes de que la animación del BottomSheet termine, lo que rompía el DOM.
              decoration: InputDecoration(
                hintText: 'Ej: Quiero compartir 2 raciones de paella...',
                suffixIcon: _cargando 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      color: context.yumColors.mintDeep,
                      onPressed: _enviarPeticion,
                    ),
              ),
              maxLines: 3,
              minLines: 1,
              enabled: !_cargando,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviarPeticion(),
            ),
          ],
        ),
      ),
    );
  }
}