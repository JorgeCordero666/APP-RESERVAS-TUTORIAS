import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
import '../../config/responsive_helper.dart';
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
      final confirmadas = todas.where((t) => t['estado'] == 'confirmada').toList();

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
        _mostrarError('Error: $e');
      }
    }
  }

  Future<void> _aceptarTutoria(String tutoriaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Aceptar Tutoría'),
        content: const Text('¿Confirmas que aceptas esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rechazar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Por qué rechazas esta solicitud?'),
            SizedBox(height: context.responsiveSpacing),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, motivoController.text),
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
      motivo.isEmpty ? 'Sin motivo' : motivo,
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

  Future<void> _reagendarTutoria(Map<String, dynamic> tutoria) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReagendarTutoriaDialog(
        tutoria: tutoria,
        nombreDocente: widget.usuario.nombre,
      ),
    );

    if (resultado != null && resultado['success'] == true) {
      _mostrarExito('Tutoría reagendada');
      _cargarSolicitudes();
    }
  }

  Future<void> _cancelarTutoria(String tutoriaId) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de cancelar?'),
            SizedBox(height: context.responsiveSpacing),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, motivoController.text),
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
      motivo: motivo.isEmpty ? 'Sin motivo' : motivo,
      canceladaPor: 'Docente',
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría cancelada');
      _cargarSolicitudes();
    }
  }

  void _mostrarError(String m) => _mostrarSnackBar(m, const Color(0xFFD32F2F), Icons.error_outline_rounded);
  void _mostrarExito(String m) => _mostrarSnackBar(m, const Color(0xFF43A047), Icons.check_circle_outline_rounded);

  void _mostrarSnackBar(String mensaje, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: context.responsiveIconSize(24)),
            SizedBox(width: context.responsiveSpacing),
            Expanded(child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Solicitudes de Tutorías',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.responsiveFontSize(19),
              ),
            ),
            Text(
              'Pendientes: $totalPendientes | Confirmadas: $totalConfirmadas',
              style: TextStyle(fontSize: context.responsiveFontSize(12), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: context.responsiveFontSize(14)),
          tabs: [
            Tab(text: 'Pendientes ($totalPendientes)'),
            Tab(text: 'Confirmadas ($totalConfirmadas)'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _cargarSolicitudes),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildListaPendientes(), _buildListaConfirmadas()],
      ),
    );
  }

  Widget _buildListaPendientes() {
    if (_isLoading) return _buildLoadingState();

    if (_tutoriasPendientes.isEmpty) {
      return _buildEmptyState(
        'No hay solicitudes pendientes',
        '¡Estás al día!',
        Icons.check_circle_outline_rounded,
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: EdgeInsets.all(context.responsivePadding),
        itemCount: _tutoriasPendientes.length,
        itemBuilder: (context, index) {
          final tutoria = _tutoriasPendientes[index];
          return _buildTutoriaCard(
            tutoria,
            Colors.orange,
            'PENDIENTE',
            showAcceptReject: true,
          );
        },
      ),
    );
  }

  Widget _buildListaConfirmadas() {
    if (_isLoading) return _buildLoadingState();

    if (_tutoriasConfirmadas.isEmpty) {
      return _buildEmptyState(
        'No hay tutorías confirmadas',
        'Las aceptadas aparecerán aquí',
        Icons.event_available_rounded,
        Colors.grey,
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: EdgeInsets.all(context.responsivePadding),
        itemCount: _tutoriasConfirmadas.length,
        itemBuilder: (context, index) {
          final tutoria = _tutoriasConfirmadas[index];
          return _buildTutoriaCard(
            tutoria,
            Colors.green,
            'CONFIRMADA',
            showReagendarCancel: true,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: context.responsiveSpacing * 2),
          Text(
            'Cargando...',
            style: TextStyle(fontSize: context.responsiveFontSize(16), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.responsiveIconSize(90), color: color),
            SizedBox(height: context.responsiveSpacing * 2),
            Text(
              title,
              style: TextStyle(fontSize: context.responsiveFontSize(19), fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing * 0.75),
            Text(
              subtitle,
              style: TextStyle(fontSize: context.responsiveFontSize(14), color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutoriaCard(
    Map<String, dynamic> tutoria,
    Color estadoColor,
    String estadoTexto, {
    bool showAcceptReject = false,
    bool showReagendarCancel = false,
  }) {
    final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;
    final padding = context.responsivePadding;
    final isMobile = context.isMobile;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: estadoColor.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 28,
                  backgroundImage: NetworkImage(
                    estudiante?['fotoPerfil'] ?? 'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                  ),
                ),
                SizedBox(width: context.responsiveSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                        style: TextStyle(fontSize: context.responsiveFontSize(16), fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isMobile) ...[
                        SizedBox(height: 4),
                        Text(
                          estudiante?['emailEstudiante'] ?? '',
                          style: TextStyle(fontSize: context.responsiveFontSize(13), color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [estadoColor.withOpacity(0.15), estadoColor.withOpacity(0.05)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: estadoColor, width: 1.5),
                  ),
                  child: Text(
                    estadoTexto,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(11),
                      fontWeight: FontWeight.w700,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: context.responsiveSpacing * 2),

            // Información
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: context.responsiveIconSize(18), color: const Color(0xFF1565C0)),
                      SizedBox(width: context.responsiveSpacing * 0.75),
                      Text(_formatearFecha(tutoria['fecha']), style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.responsiveFontSize(14))),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.75),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: context.responsiveIconSize(18), color: Colors.green),
                      SizedBox(width: context.responsiveSpacing * 0.75),
                      Text('${tutoria['horaInicio']} - ${tutoria['horaFin']}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.responsiveFontSize(14))),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: context.responsiveSpacing),

            // Botones
            if (showAcceptReject)
              isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton('Rechazar', Icons.close_rounded, Colors.red, () => _rechazarTutoria(tutoria['_id'])),
                        ),
                        SizedBox(height: context.responsiveSpacing * 0.75),
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton('Aceptar', Icons.check_rounded, Colors.green, () => _aceptarTutoria(tutoria['_id']), filled: true),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildActionButton('Rechazar', Icons.close_rounded, Colors.red, () => _rechazarTutoria(tutoria['_id']))),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(child: _buildActionButton('Aceptar', Icons.check_rounded, Colors.green, () => _aceptarTutoria(tutoria['_id']), filled: true)),
                      ],
                    ),

            if (showReagendarCancel)
              isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton('Reagendar', Icons.event_repeat_rounded, const Color(0xFF1565C0), () => _reagendarTutoria(tutoria)),
                        ),
                        SizedBox(height: context.responsiveSpacing * 0.75),
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton('Cancelar', Icons.cancel_rounded, Colors.red, () => _cancelarTutoria(tutoria['_id'])),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildActionButton('Reagendar', Icons.event_repeat_rounded, const Color(0xFF1565C0), () => _reagendarTutoria(tutoria))),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(child: _buildActionButton('Cancelar', Icons.cancel_rounded, Colors.red, () => _cancelarTutoria(tutoria['_id']))),
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool filled = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing),
          decoration: BoxDecoration(
            gradient: filled ? LinearGradient(colors: [color.withOpacity(0.9), color]) : null,
            color: filled ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: context.responsiveIconSize(20), color: filled ? Colors.white : color),
              SizedBox(width: context.responsiveSpacing * 0.5),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: context.responsiveFontSize(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}