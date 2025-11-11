// lib/servicios/notification_service.dart
import 'dart:async';

/// Servicio global para notificar cambios entre pantallas
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controllers para diferentes eventos
  final _materiasActualizadasController = StreamController<void>.broadcast();
  final _horariosActualizadosController = StreamController<void>.broadcast();

  // Streams públicos
  Stream<void> get materiasActualizadas => _materiasActualizadasController.stream;
  Stream<void> get horariosActualizados => _horariosActualizadosController.stream;

  // Métodos para notificar eventos
  void notificarMateriasActualizadas() {
    print('🔔 NotificationService: Materias actualizadas');
    if (!_materiasActualizadasController.isClosed) {
      _materiasActualizadasController.add(null);
    }
  }

  void notificarHorariosActualizados() {
    print('🔔 NotificationService: Horarios actualizados');
    if (!_horariosActualizadosController.isClosed) {
      _horariosActualizadosController.add(null);
    }
  }

  // Cleanup
  void dispose() {
    _materiasActualizadasController.close();
    _horariosActualizadosController.close();
  }
}

// Instancia global
final notificationService = NotificationService();