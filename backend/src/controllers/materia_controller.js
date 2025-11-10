// backend/src/controllers/materia_controller.js - VERSIÓN CORREGIDA
import Materia from '../models/materia.js';
import mongoose from 'mongoose';

// ========== LISTAR MATERIAS ========== 
const listarMaterias = async (req, res) => {
  try {
    const { activas, semestre } = req.query;
    
    let filtro = {};
    
    if (activas === 'true') {
      filtro.activa = true;
    }
    
    if (semestre) {
      filtro.semestre = semestre;
    }
    
    console.log('🔍 Listando materias con filtro:', filtro);
    
    const materias = await Materia.find(filtro)
      .select('-__v')
      .sort({ semestre: 1, nombre: 1 })
      .lean();
    
    console.log(`📚 Materias encontradas: ${materias.length}`);
    
    // ✅ Asegurar que creadoPor sea string
    const materiasFormateadas = materias.map(materia => ({
      ...materia,
      creadoPor: materia.creadoPor ? materia.creadoPor.toString() : ''
    }));
    
    res.status(200).json({
      success: true,
      total: materiasFormateadas.length,
      materias: materiasFormateadas
    });
    
  } catch (error) {
    console.error('❌ Error listando materias:', error);
    res.status(500).json({
      success: false,
      msg: 'Error al listar materias',
      error: error.message
    });
  }
};

// ========== CREAR MATERIA ========== 
const crearMateria = async (req, res) => {
  try {
    const { nombre, codigo, semestre, creditos, descripcion } = req.body;
    
    // ✅ CORRECCIÓN CRÍTICA: Obtener ID del admin correctamente
    const administradorId = req.administradorBDD?._id;
    
    if (!administradorId) {
      return res.status(401).json({
        success: false,
        msg: 'Administrador no autenticado'
      });
    }
    
    console.log('📝 Creando materia:', { 
      nombre, 
      codigo, 
      semestre,
      adminId: administradorId 
    });
    
    // Validaciones
    if (!nombre || !codigo || !semestre || !creditos) {
      return res.status(400).json({
        success: false,
        msg: 'Nombre, código, semestre y créditos son obligatorios'
      });
    }
    
    // Verificar duplicados por nombre
    const existeNombre = await Materia.findOne({ 
      nombre: { $regex: new RegExp(`^${nombre}$`, 'i') } 
    });
    
    if (existeNombre) {
      return res.status(400).json({
        success: false,
        msg: 'Ya existe una materia con ese nombre'
      });
    }
    
    // Verificar duplicados por código
    const existeCodigo = await Materia.findOne({ 
      codigo: codigo.toUpperCase() 
    });
    
    if (existeCodigo) {
      return res.status(400).json({
        success: false,
        msg: 'Ya existe una materia con ese código'
      });
    }
    
    // ✅ CREAR MATERIA CON ADMIN ID
    const nuevaMateria = new Materia({
      nombre: nombre.trim(),
      codigo: codigo.toUpperCase().trim(),
      semestre,
      creditos: parseInt(creditos),
      descripcion: descripcion?.trim() || '',
      creadoPor: administradorId, // ✅ Incluir admin
      activa: true
    });
    
    await nuevaMateria.save();
    
    console.log(`✅ Materia creada: ${nuevaMateria.nombre}`);
    console.log(`   ID: ${nuevaMateria._id}`);
    console.log(`   Creada por: ${nuevaMateria.creadoPor}`);
    
    // ✅ Respuesta con datos completos
    res.status(201).json({
      success: true,
      msg: 'Materia creada exitosamente',
      materia: {
        _id: nuevaMateria._id,
        nombre: nuevaMateria.nombre,
        codigo: nuevaMateria.codigo,
        semestre: nuevaMateria.semestre,
        creditos: nuevaMateria.creditos,
        descripcion: nuevaMateria.descripcion,
        activa: nuevaMateria.activa,
        creadoPor: nuevaMateria.creadoPor.toString(),
        creadaEn: nuevaMateria.creadaEn,
        actualizadaEn: nuevaMateria.actualizadaEn
      }
    });
    
  } catch (error) {
    console.error('❌ Error creando materia:', error);
    
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        msg: 'Ya existe una materia con esos datos'
      });
    }
    
    res.status(500).json({
      success: false,
      msg: 'Error al crear materia',
      error: error.message
    });
  }
};

// ========== ACTUALIZAR MATERIA ==========
const actualizarMateria = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, codigo, semestre, creditos, descripcion, activa } = req.body;
    
    console.log(`📝 Actualizando materia: ${id}`);
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        msg: 'ID de materia inválido'
      });
    }
    
    const materia = await Materia.findById(id);
    
    if (!materia) {
      return res.status(404).json({
        success: false,
        msg: 'Materia no encontrada'
      });
    }
    
    // Verificar duplicados si se cambia nombre
    if (nombre && nombre !== materia.nombre) {
      const existeNombre = await Materia.findOne({ 
        nombre: { $regex: new RegExp(`^${nombre}$`, 'i') },
        _id: { $ne: id }
      });
      
      if (existeNombre) {
        return res.status(400).json({
          success: false,
          msg: 'Ya existe otra materia con ese nombre'
        });
      }
      
      materia.nombre = nombre.trim();
    }
    
    // Verificar duplicados si se cambia código
    if (codigo && codigo.toUpperCase() !== materia.codigo) {
      const existeCodigo = await Materia.findOne({ 
        codigo: codigo.toUpperCase(),
        _id: { $ne: id }
      });
      
      if (existeCodigo) {
        return res.status(400).json({
          success: false,
          msg: 'Ya existe otra materia con ese código'
        });
      }
      
      materia.codigo = codigo.toUpperCase().trim();
    }
    
    // Actualizar campos
    if (semestre) materia.semestre = semestre;
    if (creditos !== undefined) materia.creditos = parseInt(creditos);
    if (descripcion !== undefined) materia.descripcion = descripcion.trim();
    if (activa !== undefined) materia.activa = activa;
    
    await materia.save();
    
    console.log(`✅ Materia actualizada: ${materia.nombre}`);
    
    res.status(200).json({
      success: true,
      msg: 'Materia actualizada exitosamente',
      materia: {
        _id: materia._id,
        nombre: materia.nombre,
        codigo: materia.codigo,
        semestre: materia.semestre,
        creditos: materia.creditos,
        descripcion: materia.descripcion,
        activa: materia.activa,
        creadoPor: materia.creadoPor.toString(),
        creadaEn: materia.creadaEn,
        actualizadaEn: materia.actualizadaEn
      }
    });
    
  } catch (error) {
    console.error('❌ Error actualizando materia:', error);
    res.status(500).json({
      success: false,
      msg: 'Error al actualizar materia',
      error: error.message
    });
  }
};

// ========== ELIMINAR MATERIA (SOFT DELETE) ==========
const eliminarMateria = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log(`🗑️ Desactivando materia: ${id}`);
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        msg: 'ID de materia inválido'
      });
    }
    
    const materia = await Materia.findById(id);
    
    if (!materia) {
      return res.status(404).json({
        success: false,
        msg: 'Materia no encontrada'
      });
    }
    
    // Soft delete
    materia.activa = false;
    await materia.save();
    
    console.log(`✅ Materia desactivada: ${materia.nombre}`);
    
    res.status(200).json({
      success: true,
      msg: 'Materia desactivada exitosamente',
      materia: {
        _id: materia._id,
        nombre: materia.nombre,
        activa: materia.activa
      }
    });
    
  } catch (error) {
    console.error('❌ Error eliminando materia:', error);
    res.status(500).json({
      success: false,
      msg: 'Error al eliminar materia',
      error: error.message
    });
  }
};

// ========== OBTENER DETALLE ==========
const detalleMateria = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        msg: 'ID de materia inválido'
      });
    }
    
    const materia = await Materia.findById(id)
      .select('-__v')
      .lean();
    
    if (!materia) {
      return res.status(404).json({
        success: false,
        msg: 'Materia no encontrada'
      });
    }
    
    // Formatear creadoPor
    materia.creadoPor = materia.creadoPor ? materia.creadoPor.toString() : '';
    
    res.status(200).json({
      success: true,
      materia
    });
    
  } catch (error) {
    console.error('❌ Error obteniendo detalle:', error);
    res.status(500).json({
      success: false,
      msg: 'Error al obtener detalle de materia',
      error: error.message
    });
  }
};

// ========== BUSCAR MATERIAS ==========
const buscarMaterias = async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim() === '') {
      return res.status(400).json({
        success: false,
        msg: 'Parámetro de búsqueda requerido'
      });
    }
    
    const materias = await Materia.find({
      activa: true,
      $or: [
        { nombre: { $regex: q, $options: 'i' } },
        { codigo: { $regex: q, $options: 'i' } },
        { descripcion: { $regex: q, $options: 'i' } }
      ]
    })
    .select('-__v')
    .sort({ nombre: 1 })
    .limit(20)
    .lean();
    
    // Formatear resultados
    const materiasFormateadas = materias.map(m => ({
      ...m,
      creadoPor: m.creadoPor ? m.creadoPor.toString() : ''
    }));
    
    console.log(`🔍 Búsqueda "${q}": ${materiasFormateadas.length} resultados`);
    
    res.status(200).json({
      success: true,
      total: materiasFormateadas.length,
      materias: materiasFormateadas
    });
    
  } catch (error) {
    console.error('❌ Error buscando materias:', error);
    res.status(500).json({
      success: false,
      msg: 'Error al buscar materias',
      error: error.message
    });
  }
};

export {
  listarMaterias,
  crearMateria,
  actualizarMateria,
  eliminarMateria,
  detalleMateria,
  buscarMaterias
};