import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_service.dart';
import '../../config/responsive_helper.dart';
import 'editar_perfil_screen.dart';
import '../auth/cambiar_password_screen.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const PerfilScreen({super.key, required this.usuario});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
  }

  Future<void> _actualizarUsuario() async {
    final usuarioActualizado = await AuthService.getUsuarioActual();
    if (usuarioActualizado != null && mounted) {
      setState(() {
        _usuario = usuarioActualizado;
      });
    }
  }

  Future<void> _navegarAEditar() async {
    final usuarioActualizado = await Navigator.push<Usuario>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilScreen(usuario: _usuario),
      ),
    );

    if (usuarioActualizado != null && mounted) {
      setState(() {
        _usuario = usuarioActualizado;
      });
    }
  }

  void _navegarACambiarPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CambiarPasswordScreen(usuario: _usuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.responsiveFontSize(20),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _actualizarUsuario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header con foto de perfil
              _buildHeader(),
              
              // Contenido principal
              ResponsiveHelper.centerConstrainedBox(
                context: context,
                child: Padding(
                  padding: EdgeInsets.all(context.responsivePadding),
                  child: Column(
                    children: [
                      // Información del perfil
                      _buildInfoSection(),
                      SizedBox(height: context.responsiveSpacing * 1.5),
                      
                      // Botones de acción
                      _buildActionButtons(),
                      SizedBox(height: context.responsiveSpacing * 1.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final avatarRadius = context.isMobile ? 55.0 : 60.0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.isMobile ? 30 : 40),
          bottomRight: Radius.circular(context.isMobile ? 30 : 40),
        ),
      ),
      child: Stack(
        children: [
          // Decoración con círculos sutiles
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: context.isMobile ? 120 : 150,
              height: context.isMobile ? 120 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: context.isMobile ? 100 : 120,
              height: context.isMobile ? 100 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsivePadding,
              context.responsivePadding * 1.5,
              context.responsivePadding,
              context.responsivePadding * 2.5,
            ),
            child: Column(
              children: [
                // Foto de perfil
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _navegarAEditar,
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: EdgeInsets.all(context.isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: context.responsiveIconSize(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing * 1.5),

                // Nombre
                Text(
                  _usuario.nombre,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(context.isMobile ? 22 : 24),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.responsiveSpacing * 0.75),

                // Rol
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile ? 20 : 24,
                    vertical: context.isMobile ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _usuario.esDocente ? Icons.school_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: context.responsiveIconSize(16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _usuario.rol,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(14),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
      ),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.isMobile ? 20 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1565C0).withOpacity(0.1),
                          const Color(0xFF42A5F5).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFF1565C0),
                      size: context.responsiveIconSize(22),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.75),
                  Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(context.isMobile ? 18 : 19),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1565C0),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsiveSpacing * 1.5),

              // Email
              _buildInfoItem(
                icon: Icons.email_rounded,
                label: 'Correo electrónico',
                value: _usuario.email,
              ),

              // Campos específicos por rol
              if (_usuario.esDocente) ...[
                SizedBox(height: context.responsiveSpacing),
                _buildInfoItem(
                  icon: Icons.badge_rounded,
                  label: 'Cédula',
                  value: _usuario.cedula ?? 'No especificado',
                ),
                SizedBox(height: context.responsiveSpacing),
                _buildInfoItem(
                  icon: Icons.phone_android_rounded,
                  label: 'Celular',
                  value: _usuario.celular ?? 'No especificado',
                ),
                SizedBox(height: context.responsiveSpacing),
                _buildInfoItem(
                  icon: Icons.business_rounded,
                  label: 'Oficina',
                  value: _usuario.oficina ?? 'No especificado',
                ),
                SizedBox(height: context.responsiveSpacing),
                _buildInfoItem(
                  icon: Icons.alternate_email_rounded,
                  label: 'Email alternativo',
                  value: _usuario.emailAlternativo ?? 'No especificado',
                ),
                if (_usuario.asignaturas != null &&
                    _usuario.asignaturas!.isNotEmpty) ...[
                  SizedBox(height: context.responsiveSpacing * 1.25),
                  _buildAsignaturasItem(),
                ],
              ] else if (_usuario.esEstudiante) ...[
                if (_usuario.telefono != null) ...[
                  SizedBox(height: context.responsiveSpacing),
                  _buildInfoItem(
                    icon: Icons.phone_rounded,
                    label: 'Teléfono',
                    value: _usuario.telefono!,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF42A5F5).withOpacity(0.15),
                  const Color(0xFF1E88E5).withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: context.responsiveIconSize(22),
            ),
          ),
          SizedBox(width: context.responsiveSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(15),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsignaturasItem() {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF42A5F5).withOpacity(0.15),
                      const Color(0xFF1E88E5).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: const Color(0xFF1565C0),
                  size: context.responsiveIconSize(22),
                ),
              ),
              SizedBox(width: context.responsiveSpacing),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materias',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(12),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_usuario.asignaturas!.length} asignatura(s)',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(13),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.responsiveSpacing),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _usuario.asignaturas!
                .map((materia) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.isMobile ? 14 : 16,
                        vertical: context.isMobile ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF42A5F5).withOpacity(0.1),
                            const Color(0xFF1E88E5).withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFF42A5F5).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            materia,
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(13),
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);
    
    return Column(
      children: [
        // Botón Editar Perfil
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navegarAEditar,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
            child: Ink(
              height: buttonHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF42A5F5),
                    Color(0xFF1E88E5),
                    Color(0xFF1565C0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: context.responsiveIconSize(20),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.75),
                    Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.responsiveSpacing),

        // Botón Cambiar Contraseña
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navegarACambiarPassword,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF1565C0),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: const Color(0xFF1565C0),
                      size: context.responsiveIconSize(20),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.75),
                  Text(
                    'Cambiar Contraseña',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1565C0),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}