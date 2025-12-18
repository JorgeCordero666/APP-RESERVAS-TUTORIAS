import 'package:flutter/material.dart';
import '../../servicios/tutoria_service.dart';
import '../../config/responsive_helper.dart';

class FinalizarTutoriaDialog extends StatefulWidget {
  final Map<String, dynamic> tutoria;

  const FinalizarTutoriaDialog({
    super.key,
    required this.tutoria,
  });

  @override
  State<FinalizarTutoriaDialog> createState() => _FinalizarTutoriaDialogState();
}

class _FinalizarTutoriaDialogState extends State<FinalizarTutoriaDialog> {
  bool? _asistio;
  final _observacionesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _finalizar() async {
    if (_asistio == null) {
      _mostrarError('Debes indicar si el estudiante asistió');
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await TutoriaService.finalizarTutoria(
      tutoriaId: widget.tutoria['_id'],
      asistio: _asistio!,
      observaciones: _observacionesController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      Navigator.pop(context, {'success': true});
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
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
    final estudiante = widget.tutoria['estudiante'] as Map<String, dynamic>?;
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobile;
    
    final double dialogWidth = isDesktop ? 600 : (isMobile ? MediaQuery.of(context).size.width * 0.9 : 500);
    final double iconSize = context.responsiveIconSize(28);
    final double titleSize = context.responsiveFontSize(20);
    final double contentPadding = context.responsivePadding;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.responsivePadding),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header responsive
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(contentPadding),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.responsivePadding),
                  topRight: Radius.circular(context.responsivePadding),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, 
                    color: Colors.white, 
                    size: iconSize),
                  SizedBox(width: context.responsiveSpacing),
                  Expanded(
                    child: Text(
                      'Finalizar Tutoría',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, 
                      color: Colors.white,
                      size: iconSize * 0.9),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                  ),
                ],
              ),
            ),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info de la tutoría
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.responsiveSpacing),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(context.responsiveSpacing),
                        border: Border.all(color: const Color(0xFF1565C0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: isMobile ? 18 : 20,
                                backgroundImage: NetworkImage(
                                  estudiante?['fotoPerfil'] ??
                                      'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                                ),
                              ),
                              SizedBox(width: context.responsiveSpacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: context.responsiveFontSize(16),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (!isMobile) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        estudiante?['emailEstudiante'] ?? '',
                                        style: TextStyle(
                                          fontSize: context.responsiveFontSize(12),
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: context.responsiveSpacing * 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, 
                                size: context.responsiveIconSize(16)),
                              SizedBox(width: context.responsiveSpacing * 0.5),
                              Flexible(
                                child: Text(
                                  _formatearFecha(widget.tutoria['fecha']),
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.responsiveSpacing * 0.5),
                          Row(
                            children: [
                              Icon(Icons.access_time, 
                                size: context.responsiveIconSize(16)),
                              SizedBox(width: context.responsiveSpacing * 0.5),
                              Flexible(
                                child: Text(
                                  '${widget.tutoria['horaInicio']} - ${widget.tutoria['horaFin']}',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.responsiveSpacing * 2),
                    Text(
                      '¿El estudiante asistió a la tutoría?',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing),

                    // Opciones de asistencia responsive
                    isMobile
                        ? Column(
                            children: [
                              _buildAsistenciaOption(
                                true,
                                'Sí asistió',
                                Icons.check_circle,
                                Colors.green,
                                fullWidth: true,
                              ),
                              SizedBox(height: context.responsiveSpacing),
                              _buildAsistenciaOption(
                                false,
                                'No asistió',
                                Icons.cancel,
                                Colors.red,
                                fullWidth: true,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildAsistenciaOption(
                                  true,
                                  'Sí asistió',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              SizedBox(width: context.responsiveSpacing),
                              Expanded(
                                child: _buildAsistenciaOption(
                                  false,
                                  'No asistió',
                                  Icons.cancel,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),

                    SizedBox(height: context.responsiveSpacing * 2),
                    Text(
                      'Observaciones (opcional)',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.5),
                    TextField(
                      controller: _observacionesController,
                      decoration: InputDecoration(
                        hintText: 'Ejemplo: El estudiante mostró interés...',
                        hintStyle: TextStyle(
                          fontSize: context.responsiveFontSize(14),
                        ),
                        prefixIcon: Icon(Icons.comment, 
                          size: context.responsiveIconSize(20)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveSpacing),
                        ),
                        contentPadding: EdgeInsets.all(context.responsiveSpacing),
                      ),
                      style: TextStyle(fontSize: context.responsiveFontSize(14)),
                      maxLines: isMobile ? 3 : 4,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botón responsive
            Container(
              padding: EdgeInsets.all(contentPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: context.responsiveFontSize(50),
                child: ElevatedButton(
                  onPressed: (_isLoading || _asistio == null) ? null : _finalizar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.responsiveSpacing),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _asistio == null
                              ? 'Selecciona asistencia'
                              : 'Confirmar y Finalizar',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciaOption(
    bool value,
    String label,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    final isSelected = _asistio == value;
    
    return InkWell(
      onTap: () => setState(() => _asistio = value),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.all(context.responsiveSpacing),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(context.responsiveSpacing),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: context.responsiveIconSize(32),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
                fontSize: context.responsiveFontSize(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}