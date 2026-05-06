import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coordina el indicador "escribiendo…" para una conversación concreta.
///
/// - Se suscribe a un canal Realtime por conversación (`typing-<id>`).
/// - Recibe broadcasts del otro participante y publica el estado a través
///   de [escribiendo] (true durante una ventana corta tras cada evento).
/// - Permite notificar mi propia actividad de tecleo con throttling para no
///   inundar el canal.
///
/// El controller no conoce widgets: el chat lo escucha como un
/// [ChangeNotifier] y la pantalla pinta el indicador cuando [escribiendo]
/// vale `true`.
class TypingIndicatorController extends ChangeNotifier {
  final SupabaseClient _client;
  final String conversacionId;
  final String miId;

  /// Tiempo que se considera al otro "escribiendo" después de cada evento.
  /// Si no llega otro evento dentro de esta ventana, ocultamos el indicador.
  static const Duration _ventanaActividadOtro = Duration(seconds: 4);

  /// Throttle para no broadcastear más de un `typing` por usuario cada
  /// _ventanaThrottleSelf_. El otro extremo refresca su propia ventana al
  /// recibir cada evento, así que con 2s mantenemos el indicador estable.
  static const Duration _ventanaThrottleSelf = Duration(seconds: 2);

  RealtimeChannel? _canal;
  Timer? _timerOtro;
  DateTime? _ultimoBroadcastPropio;

  bool _escribiendo = false;

  /// `true` cuando se debe pintar el indicador "escribiendo…" en la UI.
  bool get escribiendo => _escribiendo;

  TypingIndicatorController({
    required SupabaseClient client,
    required this.conversacionId,
    required this.miId,
  }) : _client = client;

  /// Conecta al canal de la conversación. Idempotente.
  void start() {
    if (_canal != null) return;

    _canal = _client
        .channel('typing-$conversacionId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final remitente = payload['usuario_id'];
            // Ignoramos los ecos propios.
            if (remitente == null || remitente == miId) return;
            _renovarVentanaOtro();
          },
        )
        .subscribe();
  }

  /// Reporta que estoy tecleando. Aplica throttling para no exceder el ratio
  /// del canal con cada pulsación de tecla.
  void notificarTecleo() {
    final canal = _canal;
    if (canal == null) return;

    final ahora = DateTime.now();
    final ultimo = _ultimoBroadcastPropio;
    if (ultimo != null && ahora.difference(ultimo) < _ventanaThrottleSelf) {
      return;
    }
    _ultimoBroadcastPropio = ahora;

    canal.sendBroadcastMessage(
      event: 'typing',
      payload: {'usuario_id': miId},
    );
  }

  /// Limpia la marca de "estoy escribiendo" tras enviar el mensaje, para que
  /// el siguiente tecleo vuelva a broadcastear inmediatamente.
  void resetearTrasEnvio() {
    _ultimoBroadcastPropio = null;
  }

  void _renovarVentanaOtro() {
    _timerOtro?.cancel();
    if (!_escribiendo) {
      _escribiendo = true;
      notifyListeners();
    }
    _timerOtro = Timer(_ventanaActividadOtro, () {
      _escribiendo = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timerOtro?.cancel();
    final canal = _canal;
    if (canal != null) {
      _client.removeChannel(canal);
      _canal = null;
    }
    super.dispose();
  }
}
