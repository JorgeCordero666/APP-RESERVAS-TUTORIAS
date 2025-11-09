// lib/pantallas/perfil/perfil_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_service.dart';
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
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navegarAEditar,
            tooltip: 'Editar perfil',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _actualizarUsuario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Foto de perfil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
                      backgroundColor: Colors.grey[300],
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _navegarAEditar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                _usuario.nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _usuario.rol,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Información del perfil
              _buildInfoSection(),

              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            _buildInfoItem(
              icon: Icons.email,
              label: 'Correo electrónico',
              value: _usuario.email,
            ),

            // Campos específicos por rol
            if (_usuario.esDocente) ...[
              const Divider(height: 24),
              _buildInfoItem(
                icon: Icons.badge,
                label: 'Cédula',
                value: _usuario.cedula ?? 'No especificado',
              ),
              const Divider(height: 24),
              _buildInfoItem(
                icon: Icons.phone,
                label: 'Celular',
                value: _usuario.celular ?? 'No especificado',
              ),
              const Divider(height: 24),
              _buildInfoItem(
                icon: Icons.meeting_room,
                label: 'Oficina',
                value: _usuario.oficina ?? 'No especificado',
              ),
              const Divider(height: 24),
              _buildInfoItem(
                icon: Icons.alternate_email,
                label: 'Email alternativo',
                value: _usuario.emailAlternativo ?? 'No especificado',
              ),
              if (_usuario.asignaturas != null &&
                  _usuario.asignaturas!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildAsignaturasItem(),
              ],
            ] else if (_usuario.esEstudiante) ...[
              if (_usuario.telefono != null) ...[
                const Divider(height: 24),
                _buildInfoItem(
                  icon: Icons.phone,
                  label: 'Teléfono',
                  value: _usuario.telefono!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF1565C0),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAsignaturasItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.book,
              color: Color(0xFF1565C0),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Materias',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _usuario.asignaturas!
              .map((materia) => Chip(
                    label: Text(
                      materia,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _navegarAEditar,
            icon: const Icon(Icons.edit),
            label: const Text(
              'Editar Perfil',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _navegarACambiarPassword,
            icon: const Icon(Icons.lock),
            label: const Text(
              'Cambiar Contraseña',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(
                color: Color(0xFF1565C0),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
