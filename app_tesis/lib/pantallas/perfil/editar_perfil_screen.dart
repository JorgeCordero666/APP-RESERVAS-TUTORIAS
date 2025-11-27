import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../servicios/auth_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarPerfilScreen({super.key, required this.usuario});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _oficinaController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailAlternativoController = TextEditingController();

  File? _imagenSeleccionada;
  bool _isLoading = false;
  bool _hasChanges = false;
  late Map<String, String> _initialValues;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _setListeners();
  }

  void _cargarDatos() {
    _nombreController.text = widget.usuario.nombre;
    _emailController.text = widget.usuario.email;
    _telefonoController.text = widget.usuario.telefono ?? '';
    _cedulaController.text = widget.usuario.cedula ?? '';
    _oficinaController.text = widget.usuario.oficina ?? '';
    _celularController.text = widget.usuario.celular ?? '';
    _emailAlternativoController.text = widget.usuario.emailAlternativo ?? '';

    _initialValues = {
      'nombre': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'cedula': _cedulaController.text.trim(),
      'oficina': _oficinaController.text.trim(),
      'celular': _celularController.text.trim(),
      'emailAlternativo': _emailAlternativoController.text.trim(),
      'imagen': widget.usuario.fotoPerfil ?? '',
    };
  }

  void _setListeners() {
    _nombreController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _telefonoController.addListener(_checkForChanges);
    _cedulaController.addListener(_checkForChanges);
    _oficinaController.addListener(_checkForChanges);
    _celularController.addListener(_checkForChanges);
    _emailAlternativoController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _telefonoController.removeListener(_checkForChanges);
    _cedulaController.removeListener(_checkForChanges);
    _oficinaController.removeListener(_checkForChanges);
    _celularController.removeListener(_checkForChanges);
    _emailAlternativoController.removeListener(_checkForChanges);

    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _oficinaController.dispose();
    _celularController.dispose();
    _emailAlternativoController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    bool changed = false;

    if (_nombreController.text.trim() != _initialValues['nombre']) changed = true;
    if (_emailController.text.trim() != _initialValues['email']) changed = true;
    if (_telefonoController.text.trim() != _initialValues['telefono']) changed = true;
    if (_cedulaController.text.trim() != _initialValues['cedula']) changed = true;
    if (_oficinaController.text.trim() != _initialValues['oficina']) changed = true;
    if (_celularController.text.trim() != _initialValues['celular']) changed = true;
    if (_emailAlternativoController.text.trim() != _initialValues['emailAlternativo']) changed = true;
    if (_imagenSeleccionada != null) changed = true;

    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede tener más de 100 caracteres';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final telefonoLimpio = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!RegExp(r'^\d+$').hasMatch(telefonoLimpio)) {
        return 'El teléfono solo debe contener números';
      }
      if (telefonoLimpio.length != 10) {
        return 'El teléfono debe tener exactamente 10 dígitos';
      }
    }
    return null;
  }

  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Seleccionar foto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Tomar foto',
                  subtitle: 'Usar la cámara',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarImagen(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Elegir de galería',
                  subtitle: 'Seleccionar imagen existente',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF8E24AA)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarImagen(ImageSource.gallery);
                  },
                ),
                if (_imagenSeleccionada != null || widget.usuario.fotoPerfil != null) ...[
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    icon: Icons.delete_rounded,
                    title: 'Eliminar foto',
                    subtitle: 'Usar foto predeterminada',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _imagenSeleccionada = null);
                    },
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => _imagenSeleccionada = File(pickedFile.path));
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.usuario.id.isEmpty) {
      _mostrarError('Error: ID de usuario no válido');
      print('❌ ERROR: widget.usuario.id está vacío');
      return;
    }

    print('🆔 ID del usuario: ${widget.usuario.id}');
    print('📧 Email del usuario: ${widget.usuario.email}');
    print('👤 Rol del usuario: ${widget.usuario.rol}');

    setState(() => _isLoading = true);

    Map<String, dynamic>? resultado;

    try {
      if (widget.usuario.esAdministrador) {
        print('🔹 Actualizando perfil de ADMINISTRADOR');
        resultado = await PerfilService.actualizarPerfilAdministrador(
          id: widget.usuario.id,
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          imagen: _imagenSeleccionada,
        );
      } else if (widget.usuario.esDocente) {
        print('🔹 Actualizando perfil de DOCENTE');
        resultado = await PerfilService.actualizarPerfilDocente(
          id: widget.usuario.id,
          nombre: _nombreController.text.trim(),
          cedula: _cedulaController.text.trim(),
          oficina: _oficinaController.text.trim(),
          email: _emailController.text.trim(),
          emailAlternativo: _emailAlternativoController.text.trim(),
          celular: _celularController.text.trim(),
          imagen: _imagenSeleccionada,
        );
      } else if (widget.usuario.esEstudiante) {
        print('🔹 Actualizando perfil de ESTUDIANTE');
        print('📝 Nombre: ${_nombreController.text.trim()}');
        print('📞 Teléfono: ${_telefonoController.text.trim()}');
        print('📧 Email: ${_emailController.text.trim()}');

        resultado = await PerfilService.actualizarPerfilEstudiante(
          id: widget.usuario.id,
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          imagen: _imagenSeleccionada,
        );
      }
    } catch (e) {
      print('❌ Error en try-catch: $e');
      resultado = {'error': 'Error inesperado: $e'};
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
      return;
    }

    _mostrarExito('Perfil actualizado correctamente');

    // Extraer el usuario del resultado
    Usuario? usuarioActualizado;
    
    if (resultado != null && resultado.containsKey('estudiante')) {
      usuarioActualizado = Usuario.fromJson(
        resultado['estudiante'], 
        widget.usuario.rol
      );
    } else if (resultado != null && resultado.containsKey('docente')) {
      usuarioActualizado = Usuario.fromJson(
        resultado['docente'], 
        widget.usuario.rol
      );
    } else if (resultado != null && resultado.containsKey('administrador')) {
      usuarioActualizado = Usuario.fromJson(
        resultado['administrador'], 
        widget.usuario.rol
      );
    }
    
    // Actualizar en SharedPreferences
    if (usuarioActualizado != null) {
      await AuthService.actualizarUsuario(usuarioActualizado);
    }

    // Actualizar estado local
    setState(() {
      _imagenSeleccionada = null;
      _hasChanges = false;
      if (usuarioActualizado != null) {
        _nombreController.text = usuarioActualizado.nombre;
        _emailController.text = usuarioActualizado.email;
        _telefonoController.text = usuarioActualizado.telefono ?? '';
        _cedulaController.text = usuarioActualizado.cedula ?? '';
        _oficinaController.text = usuarioActualizado.oficina ?? '';
        _celularController.text = usuarioActualizado.celular ?? '';
        _emailAlternativoController.text = usuarioActualizado.emailAlternativo ?? '';

        _initialValues = {
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'cedula': _cedulaController.text.trim(),
          'oficina': _oficinaController.text.trim(),
          'celular': _celularController.text.trim(),
          'emailAlternativo': _emailAlternativoController.text.trim(),
          'imagen': usuarioActualizado.fotoPerfil ?? '',
        };
      }
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    
    print('🚀 Retornando usuario actualizado: ${usuarioActualizado?.nombre}');
    Navigator.pop(context, usuarioActualizado);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  onPressed: _guardarCambios,
                  tooltip: 'Guardar cambios',
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Foto de perfil
            Center(
              child: Stack(
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
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: _imagenSeleccionada != null
                            ? FileImage(_imagenSeleccionada!)
                            : NetworkImage(widget.usuario.fotoPerfilUrl) as ImageProvider,
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
                        onTap: _mostrarOpcionesImagen,
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_imagenSeleccionada != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43A047),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Campos según el rol
            if (widget.usuario.esAdministrador) ...[
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person_rounded,
                validator: _validarNombre,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
            ] else if (widget.usuario.esDocente) ...[
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person_rounded,
                validator: _validarNombre,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cedulaController,
                label: 'Cédula de identidad',
                icon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Correo institucional',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailAlternativoController,
                label: 'Correo alternativo',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _celularController,
                label: 'Número de celular',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: _validarTelefono,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _oficinaController,
                label: 'Oficina',
                icon: Icons.business_rounded,
              ),
            ] else if (widget.usuario.esEstudiante) ...[
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person_rounded,
                validator: _validarNombre,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _telefonoController,
                label: 'Número de teléfono',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: _validarTelefono,
              ),
            ],

            const SizedBox(height: 32),

            // Botón guardar
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _guardarCambios,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: _isLoading
                        ? LinearGradient(
                            colors: [
                              Colors.grey[400]!,
                              Colors.grey[500]!,
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF42A5F5),
                              Color(0xFF1E88E5),
                              Color(0xFF1565C0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: _isLoading
                        ? null
                        : [
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
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.save_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  fontSize: 16,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.black87 : Colors.grey[600],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? [
                        const Color(0xFF42A5F5).withOpacity(0.15),
                        const Color(0xFF1E88E5).withOpacity(0.15),
                      ]
                    : [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: enabled ? const Color(0xFF1565C0) : Colors.grey[400],
              size: 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}