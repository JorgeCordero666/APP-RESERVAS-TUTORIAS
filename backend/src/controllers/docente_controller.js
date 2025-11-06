import Docente from "../models/docente.js";
import { sendMailToOwner, sendMailToRecoveryPassword } from "../config/nodemailer.js";
import { v2 as cloudinary } from 'cloudinary';
import fs from "fs-extra";
import mongoose from "mongoose";
import { crearTokenJWT } from "../middlewares/JWT.js";

// ===========================================================
// ✅ REGISTRAR DOCENTE (ACTUALIZADO CON NUEVA CORRECCIÓN)
// ===========================================================
const registrarDocente = async (req, res) => {
  try {
    const { emailDocente, fechaNacimientoDocente } = req.body;
    
    // ✅ VALIDAR CAMPOS VACÍOS
    const camposRequeridos = [
      'nombreDocente', 
      'cedulaDocente', 
      'emailDocente', 
      'celularDocente', 
      'oficinaDocente', 
      'emailAlternativoDocente',
      'fechaNacimientoDocente',
      'fechaIngresoDocente'
    ];

    const camposFaltantes = camposRequeridos.filter(campo => !req.body[campo]);
    
    if (camposFaltantes.length > 0) {
      return res.status(400).json({ 
        msg: `Los siguientes campos son obligatorios: ${camposFaltantes.join(', ')}` 
      });
    }

    // ✅ NORMALIZAR EMAILS ANTES DE VALIDAR
    const emailNormalizado = emailDocente.trim().toLowerCase();
    const emailAltNormalizado = req.body.emailAlternativoDocente.trim().toLowerCase();

    // ✅ VERIFICAR EMAIL DUPLICADO (CORRECTAMENTE)
    const emailExistente = await Docente.findOne({ emailDocente: emailNormalizado });
    if (emailExistente) {
      return res.status(400).json({ msg: 'El email institucional ya está registrado por otro docente' });
    }

    // ✅ VERIFICAR EMAIL ALTERNATIVO DUPLICADO
    const emailAltExistente = await Docente.findOne({ emailAlternativoDocente: emailAltNormalizado });
    if (emailAltExistente) {
      return res.status(400).json({ msg: 'El email alternativo ya está registrado por otro docente' });
    }

    // ✅ VERIFICAR CÉDULA DUPLICADA
    const cedulaExistente = await Docente.findOne({ cedulaDocente: req.body.cedulaDocente });
    if (cedulaExistente) {
      return res.status(400).json({ msg: 'La cédula ya está registrada' });
    }

    // ✅ VALIDAR FECHA DE NACIMIENTO
    if (fechaNacimientoDocente) {
      const fechaNac = new Date(fechaNacimientoDocente);
      const hoy = new Date();

      if (fechaNac.getFullYear() < 1960) {
        return res.status(400).json({ msg: "El año de nacimiento debe ser 1960 o posterior" });
      }

      let edad = hoy.getFullYear() - fechaNac.getFullYear();
      const mesActual = hoy.getMonth();
      const mesNac = fechaNac.getMonth();

      if (mesActual < mesNac || (mesActual === mesNac && hoy.getDate() < fechaNac.getDate())) {
        edad--;
      }

      if (edad < 18) {
        return res.status(400).json({ msg: "El docente debe tener al menos 18 años" });
      }
    }

    // ✅ GENERAR CONTRASEÑA TEMPORAL
    const password = Math.random().toString(36).toUpperCase().slice(2, 5);

    // ✅ CREAR NUEVO DOCENTE CON EMAILS NORMALIZADOS
    const nuevoDocente = new Docente({
      nombreDocente: req.body.nombreDocente,
      cedulaDocente: req.body.cedulaDocente,
      emailDocente: emailNormalizado,
      emailAlternativoDocente: emailAltNormalizado,
      celularDocente: req.body.celularDocente,
      oficinaDocente: req.body.oficinaDocente,
      fechaNacimientoDocente: req.body.fechaNacimientoDocente,
      fechaIngresoDocente: req.body.fechaIngresoDocente,
      passwordDocente: await Docente.prototype.encrypPassword("ESFOT" + password),
      administrador: req.administradorBDD._id,
      requiresPasswordChange: true,
      confirmEmail: true // ✅ Docentes creados por admin ya están confirmados
    });

    // ✅ SUBIR IMAGEN SI EXISTE
    if (req.files?.imagen) {
      const { secure_url, public_id } = await cloudinary.uploader.upload(
        req.files.imagen.tempFilePath,
        { folder: "Docentes" }
      );
      nuevoDocente.avatarDocente = secure_url;
      nuevoDocente.avatarDocenteID = public_id;
      await fs.unlink(req.files.imagen.tempFilePath);
    }

    await nuevoDocente.save();

    // ✅ ENVIAR EMAIL CON CONTRASEÑA
    await sendMailToOwner(emailDocente, "ESFOT" + password);
    console.log(`✅ Docente registrado: ${emailNormalizado}`);

    res.status(201).json({ 
      msg: "Docente registrado exitosamente. Se envió un correo con las credenciales." 
    });
  } catch (error) {
    console.error("❌ Error en registrarDocente:", error);

    // ✅ MANEJAR ERROR DE DUPLICADO DE MONGODB
    if (error.code === 11000) {
      const campo = Object.keys(error.keyPattern)[0];
      return res.status(400).json({ 
        msg: `El ${campo} ya está registrado en el sistema` 
      });
    }

    res.status(500).json({ 
      msg: "Error interno del servidor", 
      error: error.message 
    });
  }
};
// ========== CAMBIO DE CONTRASEÑA OBLIGATORIO ==========
const cambiarPasswordObligatorio = async (req, res) => {
  try {
    const { email, passwordActual, passwordNueva } = req.body;

    console.log('🔐 Cambio obligatorio para:', email);

    // Validaciones
    if (!email || !passwordActual || !passwordNueva) {
      return res.status(400).json({
        msg: "Todos los campos son obligatorios"
      });
    }

    if (passwordNueva.length < 8) {
      return res.status(400).json({
        msg: "La nueva contraseña debe tener al menos 8 caracteres"
      });
    }

    // Validación de complejidad
    if (!/[A-Z]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos una mayúscula"
      });
    }
    if (!/[a-z]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos una minúscula"
      });
    }
    if (!/[0-9]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos un número"
      });
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos un carácter especial"
      });
    }

    // Normalizar email
    const emailNormalizado = email.trim().toLowerCase();

    // Buscar docente
    const docenteBDD = await Docente.findOne({ 
      emailDocente: emailNormalizado 
    });

    if (!docenteBDD) {
      return res.status(404).json({
        msg: "Docente no encontrado"
      });
    }

    // Verificar contraseña temporal
    const verificarPassword = await docenteBDD.matchPassword(passwordActual);
    if (!verificarPassword) {
      return res.status(401).json({
        msg: "La contraseña temporal es incorrecta"
      });
    }

    // Actualizar contraseña
    docenteBDD.passwordDocente = await docenteBDD.encrypPassword(passwordNueva);
    docenteBDD.requiresPasswordChange = false;  // Ya cambió la contraseña
    
    await docenteBDD.save();

    console.log(`✅ Contraseña cambiada exitosamente: ${emailNormalizado}`);

    res.status(200).json({
      success: true,
      msg: "Contraseña actualizada correctamente"
    });
  } catch (error) {
    console.error("❌ Error en cambio obligatorio:", error);
    res.status(500).json({
      msg: "Error al cambiar contraseña",
      error: error.message
    });
  }
};

// ========== RECUPERACIÓN DE CONTRASEÑA ==========
const recuperarPasswordDocente = async (req, res) => {
  try {
    const { emailDocente } = req.body;

    console.log('📨 Solicitud de recuperación docente:', { emailDocente });

    if (!emailDocente) {
      return res.status(400).json({ 
        success: false,
        msg: "El email es obligatorio" 
      });
    }

    // Normalizar email
    const emailNormalizado = emailDocente.trim().toLowerCase();

    console.log('🔍 Buscando docente con email:', emailNormalizado);

    const docenteBDD = await Docente.findOne({ 
      emailDocente: emailNormalizado 
    });

    if (!docenteBDD) {
      console.log(`ℹ️ Email de docente no encontrado: ${emailNormalizado}`);
      return res.status(404).json({ 
        success: false,
        msg: "Lo sentimos, el usuario no existe" 
      });
    }

    console.log('✅ Docente encontrado:', docenteBDD.nombreDocente);

    // Generar token de recuperación
    const token = docenteBDD.crearToken();
    docenteBDD.token = token;

    await sendMailToRecoveryPassword(emailDocente, token);
    await docenteBDD.save();

    console.log(`✅ Email de recuperación enviado a docente: ${emailDocente}`);

    res.status(200).json({ 
      success: true,
      msg: "Revisa tu correo electrónico para restablecer tu contraseña.",
      email: emailDocente
    });
  } catch (error) {
    console.error("❌ Error en recuperación de password docente:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al procesar solicitud",
      error: error.message
    });
  }
};

const comprobarTokenPasswordDocente = async (req, res) => {
  try {
    const { token } = req.params;

    console.log('🔍 Comprobando token de docente:', token);

    if (!token) {
      return res.status(400).json({ 
        success: false,
        msg: "Token no proporcionado" 
      });
    }

    const docenteBDD = await Docente.findOne({ token });

    if (!docenteBDD || docenteBDD.token !== token) {
      console.log('❌ Token de docente no encontrado o ya usado');
      return res.status(404).json({ 
        success: false,
        msg: "Lo sentimos, no se puede validar la cuenta" 
      });
    }

    console.log('✅ Token de docente válido para:', docenteBDD.emailDocente);

    res.status(200).json({ 
      success: true,
      msg: "Token confirmado, ya puedes crear tu password" 
    });
  } catch (error) {
    console.error("❌ Error comprobando token docente:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al validar token" 
    });
  }
};

const crearNuevoPasswordDocente = async (req, res) => {
  try {
    const { password, confirmpassword } = req.body;
    const { token } = req.params;

    console.log('🔐 Creando nueva contraseña para docente con token:', token);

    if (!password || !confirmpassword) {
      return res.status(400).json({ 
        success: false,
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }

    if (password !== confirmpassword) {
      return res.status(400).json({ 
        success: false,
        msg: "Lo sentimos, los passwords no coinciden" 
      });
    }

    if (password.length < 8) {
      return res.status(400).json({ 
        success: false,
        msg: "La contraseña debe tener al menos 8 caracteres" 
      });
    }

    const docenteBDD = await Docente.findOne({ token });

    if (!docenteBDD || docenteBDD.token !== token) {
      console.log('❌ Token de docente no encontrado');
      return res.status(404).json({ 
        success: false,
        msg: "Lo sentimos, no se puede validar su cuenta" 
      });
    }

    console.log('✅ Actualizando contraseña de docente:', docenteBDD.emailDocente);

    docenteBDD.token = null;
    docenteBDD.passwordDocente = await docenteBDD.encrypPassword(password);
    await docenteBDD.save();

    console.log(`✅ Contraseña de docente actualizada exitosamente`);

    res.status(200).json({ 
      success: true,
      msg: "Ya puede iniciar sesión con su nueva contraseña.",
      email: docenteBDD.emailDocente
    });
  } catch (error) {
    console.error("❌ Error creando nueva contraseña docente:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al actualizar contraseña" 
    });
  }
};

// ===========================================================
// ✅ LISTAR DOCENTES (INCLUYE INACTIVOS PARA ADMIN)
// ===========================================================
const listarDocentes = async (req, res) => {
  try {
    let filtro = {};

    if (req.administradorBDD) {
      // Admin ve TODOS los docentes (activos e inactivos)
      filtro.administrador = req.administradorBDD._id;
    } else if (req.estudianteBDD) {
      // Estudiantes solo ven docentes activos
      filtro.estadoDocente = true;
    } else {
      return res.status(403).json({ msg: "No autorizado para ver docentes" });
    }

    const docentes = await Docente.find(filtro)
      .select("-salida -createdAt -updatedAt -__v -passwordDocente -token")
      .sort({ estadoDocente: -1, nombreDocente: 1 }); // Activos primero

    // ✅ Asegurar que asignaturas sea siempre un array
    const docentesFormateados = docentes.map(doc => {
      const docenteObj = doc.toObject();
      if (typeof docenteObj.asignaturas === "string") {
        try {
          docenteObj.asignaturas = JSON.parse(docenteObj.asignaturas);
        } catch {
          docenteObj.asignaturas = [];
        }
      }
      return docenteObj;
    });

    return res.status(200).json({ 
      total: docentesFormateados.length,
      docentes: docentesFormateados 
    });
  } catch (error) {
    console.error("Error al listar docentes:", error);
    return res.status(500).json({ 
      msg: "Error al listar docentes", 
      error: error.message 
    });
  }
};

// ========== DETALLE DE DOCENTE ==========
const detalleDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(404).json({ 
        msg: `Lo sentimos, no existe el registro del docente ${id}` 
      });
    }
    
    const docente = await Docente.findById(id)
      .select("-createdAt -updatedAt -__v")
      .populate('administrador', '_id nombre apellido');

    if (!docente) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }

    // Validar asignaturas
    if (docente && typeof docente.asignaturas === "string") {
      try {
        docente.asignaturas = JSON.parse(docente.asignaturas);
      } catch {
        docente.asignaturas = [];
      }
    }

    res.status(200).json(docente);
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al obtener detalle", 
      error 
    });
  }
};

// ========== ELIMINAR DOCENTE - LÍNEA 452 APROXIMADAMENTE ==========
// ANTES: Solo cambiaba estadoDocente a false
// AHORA: Elimina FÍSICAMENTE de la BD

const eliminarDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!req.body.salidaDocente) {
      return res.status(400).json({ 
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(404).json({ 
        msg: `Lo sentimos, no existe el docente ${id}` 
      });
    }
    
    // ✅ OPCIÓN 1: ELIMINACIÓN FÍSICA (recomendado si realmente quieres borrar)
    const docenteEliminado = await Docente.findByIdAndDelete(id);
    
    if (!docenteEliminado) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }
    
    console.log(`🗑️ Docente eliminado permanentemente: ${docenteEliminado.nombreDocente}`);
    
    res.status(200).json({ 
      msg: "El docente fue eliminado permanentemente del sistema.",
      eliminado: true
    });
    
    // ✅ OPCIÓN 2: SOFT DELETE (si quieres mantener el historial)
    // Descomenta esto si prefieres mantener el registro pero marcarlo como eliminado
    /*
    const { salidaDocente } = req.body;
    
    const docenteActualizado = await Docente.findByIdAndUpdate(id, {
      salidaDocente: new Date(salidaDocente),
      estadoDocente: false
    }, { new: true });
    
    if (!docenteActualizado) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }
    
    console.log(`🔒 Docente deshabilitado: ${docenteActualizado.nombreDocente}`);
    
    res.status(200).json({ 
      msg: "El registro fue deshabilitado con éxito.",
      eliminado: false
    });
    */
  } catch (error) {
    console.error("Error en eliminarDocente:", error);
    res.status(500).json({ 
      msg: "Error al eliminar docente", 
      error: error.message 
    });
  }
};

// ========== ACTUALIZAR DOCENTE (POR ADMINISTRADOR) ==========
const actualizarDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (Object.values(req.body).includes("")) {
      return res.status(400).json({ 
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(404).json({ 
        msg: `Lo sentimos, no existe el docente ${id}` 
      });
    }

    let asignaturas = req.body.asignaturas;
    if (typeof asignaturas === "string") {
      try {
        asignaturas = JSON.parse(asignaturas);
      } catch {
        return res.status(400).json({ 
          msg: "Formato inválido en asignaturas" 
        });
      }
    }
    req.body.asignaturas = asignaturas;

    if (req.files?.imagen) {
      const docente = await Docente.findById(id);
      if (docente.avatarDocenteID) {
        await cloudinary.uploader.destroy(docente.avatarDocenteID);
      }
      const cloudiResponse = await cloudinary.uploader.upload(
        req.files.imagen.tempFilePath,
        { folder: 'Docentes' }
      );
      req.body.avatarDocente = cloudiResponse.secure_url;
      req.body.avatarDocenteID = cloudiResponse.public_id;
      await fs.unlink(req.files.imagen.tempFilePath);
    }
    
    const docenteActualizado = await Docente.findByIdAndUpdate(id, req.body, { new: true })
      .select("-passwordDocente -confirmEmail -createdAt -updatedAt -__v");
    
    res.status(200).json({ docente: docenteActualizado });
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al actualizar docente", 
      error 
    });
  }
};

// ========== LOGIN DOCENTE ==========
const loginDocente = async (req, res) => {
  try {
    const { email: emailDocente, password: passwordDocente } = req.body;
    
    if (!emailDocente || !passwordDocente) {
      return res.status(400).json({ 
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }
    
    const docenteBDD = await Docente.findOne({ emailDocente });
    
    if (!docenteBDD) {
      return res.status(404).json({ 
        msg: "Lo sentimos, el usuario no se encuentra registrado" 
      });
    }
    
    const verificarPassword = await docenteBDD.matchPassword(passwordDocente);
    
    if (!verificarPassword) {
      return res.status(401).json({ 
        msg: "Lo sentimos, el password no es el correcto" 
      });
    }
    
    const token = crearTokenJWT(docenteBDD._id, docenteBDD.rol);
    const { _id, rol, avatarDocente, requiresPasswordChange } = docenteBDD;
    
    // ✅ CONSTRUIR RESPUESTA CON FLAG CONDICIONAL
    const response = { 
      token, 
      rol, 
      _id, 
      avatarDocente 
    };

    // Solo agregar requiresPasswordChange si es true
    if (requiresPasswordChange === true) {
      response.requiresPasswordChange = true;
    }

    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al iniciar sesión", 
      error 
    });
  }
};

// ========== PERFIL DOCENTE ==========
const perfilDocente = (req, res) => {
  try {
    const docente = req.docenteBDD;
    
    if (!docente) {
      return res.status(404).json({ 
        msg: "Docente no encontrado." 
      });
    }
    
    const camposAEliminar = [
      "fechaIngresoDocente", 
      "salidaDocente",
      "estadoDocente", 
      "passwordDocente", 
      "confirmEmail", 
      "createdAt", 
      "updatedAt", 
      "__v"
    ];
    
    camposAEliminar.forEach(campo => delete req.docenteBDD[campo]);
    
    res.status(200).json(req.docenteBDD);
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al obtener perfil", 
      error 
    });
  }
};

// ========== ACTUALIZAR PERFIL DOCENTE (POR ÉL MISMO) ==========
// backend/src/controllers/docente_controller.js
// ✅ FUNCIÓN CORREGIDA - actualizarPerfilDocente

const actualizarPerfilDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    // ✅ PERMITIR: Docente edita su propio perfil O Admin edita cualquier perfil
    const esDocente = req.docenteBDD && req.docenteBDD._id.toString() === id;
    const esAdmin = req.administradorBDD;
    
    if (!esDocente && !esAdmin) {
      return res.status(403).json({ 
        msg: "No tienes permiso para modificar este perfil" 
      });
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        msg: "ID de docente inválido" 
      });
    }

    const docenteBDD = await Docente.findById(id);
    
    if (!docenteBDD) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }

    // ========================================
    // ✅ EXTRAER DATOS DEL REQUEST
    // ========================================
    const { 
      nombreDocente, 
      celularDocente, 
      oficinaDocente, 
      emailAlternativoDocente,
      semestreAsignado,
      asignaturas 
    } = req.body;

    console.log('📥 Datos recibidos para actualizar:');
    console.log('   nombreDocente:', nombreDocente);
    console.log('   semestreAsignado:', semestreAsignado);
    console.log('   asignaturas (raw):', asignaturas);
    console.log('   tipo de asignaturas:', typeof asignaturas);

    // ========================================
    // ✅ ACTUALIZAR CAMPOS BÁSICOS
    // ========================================
    if (nombreDocente !== undefined && nombreDocente.trim() !== '') {
      if (nombreDocente.trim().length < 3) {
        return res.status(400).json({
          msg: "El nombre debe tener al menos 3 caracteres"
        });
      }
      docenteBDD.nombreDocente = nombreDocente.trim();
      console.log('✅ Nombre actualizado');
    }

    if (celularDocente !== undefined && celularDocente.trim() !== '') {
      const telefonoLimpio = celularDocente.replace(/[\s\-\(\)]/g, '');
      if (!/^\d+$/.test(telefonoLimpio)) {
        return res.status(400).json({
          msg: "El teléfono solo debe contener números"
        });
      }
      if (telefonoLimpio.length !== 10) {
        return res.status(400).json({
          msg: "El teléfono debe tener exactamente 10 dígitos"
        });
      }
      docenteBDD.celularDocente = telefonoLimpio;
      console.log('✅ Celular actualizado');
    }

    if (oficinaDocente !== undefined && oficinaDocente.trim() !== '') {
      docenteBDD.oficinaDocente = oficinaDocente.trim();
      console.log('✅ Oficina actualizada');
    }

    if (emailAlternativoDocente !== undefined && emailAlternativoDocente.trim() !== '') {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(emailAlternativoDocente)) {
        return res.status(400).json({
          msg: "Por favor ingresa un email alternativo válido"
        });
      }
      
      const emailExistente = await Docente.findOne({ 
        emailAlternativoDocente: emailAlternativoDocente.toLowerCase() 
      });
      
      if (emailExistente && emailExistente._id.toString() !== id) {
        return res.status(400).json({
          msg: "El email alternativo ya está en uso por otro docente"
        });
      }
      
      docenteBDD.emailAlternativoDocente = emailAlternativoDocente.toLowerCase();
      console.log('✅ Email alternativo actualizado');
    }

    // ========================================
    // ✅ ACTUALIZAR SEMESTRE
    // ========================================
    if (semestreAsignado !== undefined && semestreAsignado !== null) {
      const semestresValidos = ['Nivelacion', 'Primer Semestre'];
      
      if (!semestresValidos.includes(semestreAsignado)) {
        return res.status(400).json({
          msg: "Semestre inválido. Debe ser 'Nivelacion' o 'Primer Semestre'"
        });
      }
      
      docenteBDD.semestreAsignado = semestreAsignado;
      console.log(`✅ Semestre actualizado: ${semestreAsignado}`);
    }

    // ========================================
    // ✅ ACTUALIZAR ASIGNATURAS (CRÍTICO)
    // ========================================
    if (asignaturas !== undefined) {
      console.log('🔄 Procesando asignaturas...');
      
      let asignaturasArray = [];
      
      // ✅ Manejar diferentes formatos
      if (typeof asignaturas === 'string') {
        try {
          // Intentar parsear si viene como JSON string
          asignaturasArray = JSON.parse(asignaturas);
          console.log('   ✅ Parseado desde string JSON');
        } catch (e) {
          // Si no es JSON, asumir que es un array vacío
          console.log('   ⚠️ No se pudo parsear, usando array vacío');
          asignaturasArray = [];
        }
      } else if (Array.isArray(asignaturas)) {
        asignaturasArray = asignaturas;
        console.log('   ✅ Ya es un array');
      } else if (asignaturas === null) {
        asignaturasArray = [];
        console.log('   ℹ️ Asignaturas es null, usando array vacío');
      }
      
      // ✅ Validar que todos los elementos sean strings
      if (!Array.isArray(asignaturasArray)) {
        return res.status(400).json({
          msg: "Asignaturas debe ser un array"
        });
      }

      // ✅ Filtrar valores vacíos
      asignaturasArray = asignaturasArray.filter(a => 
        a && typeof a === 'string' && a.trim() !== ''
      );

      // ✅ GUARDAR DIRECTAMENTE COMO ARRAY (NO COMO STRING)
      docenteBDD.asignaturas = asignaturasArray;
      
      console.log(`✅ Asignaturas actualizadas: ${asignaturasArray.length} materias`);
      console.log(`   Materias: ${asignaturasArray.join(', ')}`);
    }

    // ========================================
    // ✅ ACTUALIZAR FOTO DE PERFIL
    // ========================================
    if (req.files?.imagen) {
      try {
        if (docenteBDD.avatarDocenteID) {
          await cloudinary.uploader.destroy(docenteBDD.avatarDocenteID);
        }

        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
        if (!allowedTypes.includes(req.files.imagen.mimetype)) {
          await fs.unlink(req.files.imagen.tempFilePath);
          return res.status(400).json({
            msg: "Solo se permiten imágenes en formato JPG, JPEG o PNG"
          });
        }

        const maxSize = 5 * 1024 * 1024;
        if (req.files.imagen.size > maxSize) {
          await fs.unlink(req.files.imagen.tempFilePath);
          return res.status(400).json({
            msg: "La imagen no debe superar los 5MB"
          });
        }

        const { secure_url, public_id } = await cloudinary.uploader.upload(
          req.files.imagen.tempFilePath,
          {
            folder: "Docentes",
            transformation: [
              { width: 500, height: 500, crop: "limit" },
              { quality: "auto:good" }
            ]
          }
        );

        docenteBDD.avatarDocente = secure_url;
        docenteBDD.avatarDocenteID = public_id;

        await fs.unlink(req.files.imagen.tempFilePath);
        console.log('✅ Foto actualizada');
      } catch (cloudinaryError) {
        console.error("Error subiendo imagen:", cloudinaryError);
        return res.status(500).json({
          msg: "Error al subir la imagen. Intenta con una imagen más pequeña."
        });
      }
    }

    // ========================================
    // ✅ GUARDAR EN BASE DE DATOS
    // ========================================
    await docenteBDD.save();

    console.log('💾 Cambios guardados en BD');

    // ========================================
    // ✅ OBTENER DOCENTE ACTUALIZADO
    // ========================================
    const docenteActualizado = await Docente.findById(id)
      .select('-passwordDocente -token -__v -createdAt -updatedAt');

    console.log('📤 Enviando respuesta:');
    console.log('   ID:', docenteActualizado._id);
    console.log('   Nombre:', docenteActualizado.nombreDocente);
    console.log('   Semestre:', docenteActualizado.semestreAsignado);
    console.log('   Asignaturas:', docenteActualizado.asignaturas);

    res.status(200).json({
      success: true,
      msg: "Perfil actualizado con éxito",
      docente: docenteActualizado
    });

  } catch (error) {
    console.error("❌ Error actualizando perfil:", error);
    res.status(500).json({ 
      msg: "Error al actualizar perfil", 
      error: error.message 
    });
  }
};

// ========== ACTUALIZAR CONTRASEÑA DOCENTE (POR ÉL MISMO) ==========
const actualizarPasswordDocente = async (req, res) => {
  try {
    const { passwordactual, passwordnuevo } = req.body;

    if (!passwordactual || !passwordnuevo) {
      return res.status(400).json({
        msg: "Debes proporcionar la contraseña actual y la nueva contraseña"
      });
    }

    if (passwordnuevo.length < 8) {
      return res.status(400).json({
        msg: "La nueva contraseña debe tener al menos 8 caracteres"
      });
    }

    const docenteBDD = await Docente.findById(req.docenteBDD._id);

    if (!docenteBDD) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }

    const verificarPassword = await docenteBDD.matchPassword(passwordactual);

    if (!verificarPassword) {
      return res.status(401).json({ 
        msg: "La contraseña actual es incorrecta" 
      });
    }

    docenteBDD.passwordDocente = await docenteBDD.encrypPassword(passwordnuevo);
    await docenteBDD.save();

    console.log(`✅ Contraseña actualizada: ${docenteBDD.emailDocente}`);

    res.status(200).json({
      success: true,
      msg: "Contraseña actualizada correctamente"
    });
  } catch (error) {
    console.error("Error actualizando contraseña:", error);
    res.status(500).json({ 
      msg: "Error al actualizar contraseña", 
      error: error.message 
    });
  }
};

// ========== EXPORTACIONES ==========
export {
  registrarDocente,
  listarDocentes,
  detalleDocente,
  eliminarDocente,
  actualizarDocente,
  loginDocente,
  perfilDocente,
  recuperarPasswordDocente,
  comprobarTokenPasswordDocente,
  crearNuevoPasswordDocente,
  actualizarPerfilDocente,      
  actualizarPasswordDocente,
  cambiarPasswordObligatorio    
};