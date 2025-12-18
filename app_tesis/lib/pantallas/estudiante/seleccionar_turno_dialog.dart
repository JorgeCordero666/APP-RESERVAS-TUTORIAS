import 'package:flutter/material.dart';
import '../../servicios/tutoria_service.dart';
import '../../config/responsive_helper.dart';

class SeleccionarTurnoDialog extends StatefulWidget {
  final String docenteId;
  final String nombreDocente;
  final DateTime fecha;
  final String bloqueInicio;
  final String bloqueFin;

  const SeleccionarTurnoDialog({
    super.key,
    required this.docenteId,
    required this.nombreDocente,
    required this.fecha,
    required this.bloqueInicio,
    required this.bloqueFin,
  });

  @override
  State<SeleccionarTurnoDialog> createState() => _SeleccionarTurnoDialogState();
}

class _SeleccionarTurnoDialogState extends State<SeleccionarTurnoDialog> 
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _turnosData;
  String? _turnoSeleccionado;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    _cargarTurnos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarTurnos() async {
    setState(() => _isLoading = true);

    final fechaStr = widget.fecha.toIso8601String().split('T')[0];

    final resultado = await TutoriaService.obtenerTurnosDisponibles(
      docenteId: widget.docenteId,
      fecha: fechaStr,
      horaInicio: widget.bloqueInicio,
      horaFin: widget.bloqueFin,
    );

    if (!mounted) return;

    if (resultado != null && !resultado.containsKey('error')) {
      setState(() {
        _turnosData = resultado;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _mostrarError(resultado?['error'] ?? 'Error al cargar turnos');
    }
  }

  Future<void> _agendarTurno() async {
    if (_turnoSeleccionado == null) {
      _mostrarError('Debes seleccionar un turno');
      return;
    }

    final partes = _turnoSeleccionado!.split(' - ');
    if (partes.length != 2) {
      _mostrarError('Turno inválido');
      return;
    }

    final horaInicio = partes[0];
    final horaFin = partes[1];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: context.isMobile ? 24 : 28,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Confirmar Turno',
                style: TextStyle(fontSize: context.responsiveFontSize(18)),
              ),
            ),
          ],
        ),
        content: Container(
          padding: EdgeInsets.all(context.responsivePadding),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.person, 'Docente', widget.nombreDocente),
              SizedBox(height: context.responsiveSpacing),
              _buildInfoRow(Icons.calendar_today, 'Fecha', _formatearFecha(widget.fecha)),
              SizedBox(height: context.responsiveSpacing),
              _buildInfoRow(Icons.access_time, 'Turno', '$horaInicio - $horaFin'),
              SizedBox(height: context.responsiveSpacing),
              _buildInfoRow(Icons.timer, 'Duración', '20 minutos'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 16 : 20,
                vertical: 12,
              ),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 20 : 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    _mostrarCargando();

    final fechaStr = widget.fecha.toIso8601String().split('T')[0];

    final resultado = await TutoriaService.agendarTurno(
      docenteId: widget.docenteId,
      fecha: fechaStr,
      horaInicio: horaInicio,
      horaFin: horaFin,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (resultado != null && !resultado.containsKey('error')) {
      _mostrarExito('¡Turno agendado! El docente revisará tu solicitud');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      _mostrarError(resultado?['error'] ?? 'Error al agendar turno');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: context.responsiveIconSize(20),
          color: Colors.blue[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final dia = dias[fecha.weekday - 1];
    return '$dia ${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.all(context.isMobile ? 24 : 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                SizedBox(height: context.isMobile ? 16 : 20),
                Text(
                  'Agendando turno...',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = context.isDesktop ? 500.0 : (context.isTablet ? 450.0 : double.infinity);
    final maxHeight = context.isDesktop ? 700.0 : (context.isTablet ? 650.0 : double.infinity);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        ),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.responsivePadding),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveHelper.getBorderRadius(context)),
                    topRight: Radius.circular(ResponsiveHelper.getBorderRadius(context)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: context.responsiveIconSize(24),
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(
                          child: Text(
                            'Seleccionar Turno',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsiveFontSize(20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: context.responsiveIconSize(24),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: context.responsiveIconSize(14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Turnos de 20 minutos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsiveFontSize(13),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.responsivePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            size: context.responsiveIconSize(20),
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(
                          child: Text(
                            widget.nombreDocente,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.responsiveFontSize(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: context.responsiveIconSize(16),
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatearFecha(widget.fecha),
                          style: TextStyle(fontSize: context.responsiveFontSize(14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: context.responsiveIconSize(16),
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.bloqueInicio} - ${widget.bloqueFin}',
                          style: TextStyle(fontSize: context.responsiveFontSize(14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(context.responsivePadding),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(strokeWidth: 3),
                            ),
                            SizedBox(height: context.responsiveSpacing * 1.5),
                            Text(
                              'Cargando turnos disponibles...',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(15),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _turnosData == null
                        ? const Center(
                            child: Text('Error al cargar turnos'),
                          )
                        : _buildListaTurnos(),
              ),

              if (!_isLoading && _turnosData != null)
                Container(
                  padding: EdgeInsets.all(context.responsivePadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: _turnoSeleccionado != null ? _agendarTurno : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _turnoSeleccionado != null 
                                ? Icons.check_circle_outline 
                                : Icons.schedule,
                            size: context.responsiveIconSize(22),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _turnoSeleccionado != null
                                ? 'Agendar Turno'
                                : 'Selecciona un turno',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaTurnos() {
    final turnos = _turnosData!['turnos'];
    final disponibles = turnos['disponibles'] as int;
    final total = turnos['total'] as int;
    final lista = turnos['lista'] as List;

    if (disponibles == 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(context.isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy,
                  size: context.isMobile ? 48 : 60,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: context.responsiveSpacing * 1.5),
              Text(
                'No hay turnos disponibles',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.responsiveSpacing * 0.6),
              Text(
                'Todos los turnos ($total) están ocupados',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(14),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.responsivePadding),
          child: Wrap(
            spacing: context.isMobile ? 8 : 12,
            runSpacing: context.isMobile ? 8 : 12,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildStat(
                'Disponibles',
                disponibles.toString(),
                Colors.green,
                Icons.check_circle,
              ),
              _buildStat(
                'Ocupados',
                (total - disponibles).toString(),
                Colors.red,
                Icons.cancel,
              ),
              _buildStat(
                'Total',
                total.toString(),
                Colors.blue,
                Icons.schedule,
              ),
            ],
          ),
        ),

        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: context.responsivePadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(context.responsivePadding),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final turno = lista[index];
              final horaInicio = turno['horaInicio'];
              final horaFin = turno['horaFin'];
              final turnoKey = '$horaInicio - $horaFin';
              final isSelected = _turnoSeleccionado == turnoKey;

              return Padding(
                padding: EdgeInsets.only(bottom: context.responsiveSpacing),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _turnoSeleccionado = turnoKey;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(context.responsivePadding),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0).withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.green[400]!,
                                      Colors.green[600]!,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                        ? const Color(0xFF1565C0)
                                        : Colors.green)
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.access_time,
                            color: Colors.white,
                            size: context.responsiveIconSize(28),
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                turnoKey,
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(18),
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: context.responsiveIconSize(14),
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '20 minutos',
                                    style: TextStyle(
                                      fontSize: context.responsiveFontSize(13),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF1565C0),
                            size: context.responsiveIconSize(20),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: context.responsiveIconSize(28),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsiveFontSize(12),
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}