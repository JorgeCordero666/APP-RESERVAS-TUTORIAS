// lib/pantallas/docente/solicitudes_tutorias_screen.dart - VERSIÓN CORREGIDA
// Incluye reagendamiento y cancelación para docente en tutorías confirmadas.

import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
import '../estudiante/reagendar_tutoria_dialog.dart';

class SolicitudesTutoriasScreen extends StatefulWidget {
  final Usuario usuario;

  const SolicitudesTutoriasScreen({super.key, required this.usuario});

  @override
  State<SolicitudesTutoriasScreen> createState() => _SolicitudesTutoriasScreenState();
}

class _SolicitudesTutoriasScreenState extends State<SolicitudesTutoriasScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _tutoriasPendientes = [];
  List<Map<String, dynamic>> _tutoriasConfirmadas = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoading = true);

    try {
      final pendientes = await TutoriaService.listarTutoriasPendientes();
      final todas = await TutoriaService.listarTutorias(incluirCanceladas: false);

      final confirmadas =
          todas.where((t) => t['estado'] == 'confirmada').toList();

      if (mounted) {
        setState(() {
          _tutoriasPendientes = pendientes;
          _tutoriasConfirmadas = confirmadas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar solicitudes: $e');
      }
    }
  }

  Future<void> _aceptarTutoria(String tutoriaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Tutoría'),
        content: const Text('¿Confirmas que aceptas esta solicitud de tutoría?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);
    final resultado = await TutoriaService.aceptarTutoria(tutoriaId);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría aceptada exitosamente');
      _cargarSolicitudes();
    }
  }

  Future<void> _rechazarTutoria(String tutoriaId) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué rechazas esta solicitud?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivoController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (motivo == null) return;

    setState(() => _isLoading = true);
    final resultado = await TutoriaService.rechazarTutoria(
      tutoriaId,
      motivo.isEmpty ? 'Sin motivo especificado' : motivo,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría rechazada');
      _cargarSolicitudes();
    }
  }

  // ============================================================
  //  REAGENDAMIENTO PARA DOCENTE
  // ============================================================
  Future<void> _reagendarTutoria(Map<String, dynamic> tutoria) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReagendarTutoriaDialog(
        tutoria: tutoria,
        nombreDocente: widget.usuario.nombre,
      ),
    );

    if (resultado != null && resultado['success'] == true) {
      _mostrarExito('Tutoría reagendada exitosamente');
      _cargarSolicitudes();
    }
  }

  // ============================================================
  //  CANCELACIÓN PARA DOCENTE
  // ============================================================
  Future<void> _cancelarTutoria(String tutoriaId) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de cancelar esta tutoría?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivoController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (motivo == null) return;

    setState(() => _isLoading = true);

    final resultado = await TutoriaService.cancelarTutoria(
      tutoriaId: tutoriaId,
      motivo: motivo.isEmpty ? 'Sin motivo especificado' : motivo,
      canceladaPor: 'Docente',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría cancelada exitosamente');
      _cargarSolicitudes();
    }
  }

  // ============================================================
  //  UTILIDADES
  // ============================================================
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPendientes = _tutoriasPendientes.length;
    final totalConfirmadas = _tutoriasConfirmadas.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitudes ($totalPendientes) | Confirmadas ($totalConfirmadas)'),
        backgroundColor: const Color(0xFF1565C0),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Pendientes ($totalPendientes)'),
            Tab(text: 'Confirmadas ($totalConfirmadas)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaPendientes(),
          _buildListaConfirmadas(),
        ],
      ),
    );
  }

  // ============================================================
  //  LISTA DE TUTORÍAS PENDIENTES
  // ============================================================
  Widget _buildListaPendientes() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tutoriasPendientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'No tienes solicitudes pendientes',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tutoriasPendientes.length,
        itemBuilder: (context, index) {
          final tutoria = _tutoriasPendientes[index];
          final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                          estudiante?['fotoPerfil'] ??
                              'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              estudiante?['emailEstudiante'] ?? '',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PENDIENTE',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(_formatearFecha(tutoria['fecha'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text('${tutoria['horaInicio']} - ${tutoria['horaFin']}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rechazarTutoria(tutoria['_id']),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rechazar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _aceptarTutoria(tutoria['_id']),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Aceptar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  //  LISTA DE TUTORÍAS CONFIRMADAS
  // ============================================================
  Widget _buildListaConfirmadas() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tutoriasConfirmadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes tutorías confirmadas',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tutoriasConfirmadas.length,
        itemBuilder: (context, index) {
          final tutoria = _tutoriasConfirmadas[index];
          final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                          estudiante?['fotoPerfil'] ??
                              'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              estudiante?['emailEstudiante'] ?? '',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'CONFIRMADA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(_formatearFecha(tutoria['fecha'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text('${tutoria['horaInicio']} - ${tutoria['horaFin']}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reagendarTutoria(tutoria),
                          icon: const Icon(Icons.event_repeat, size: 18),
                          label: const Text('Reagendar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelarTutoria(tutoria['_id']),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
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
