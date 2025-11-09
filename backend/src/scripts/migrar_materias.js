// backend/src/scripts/migrar_materias.js
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Materia from '../models/materia.js';
import Administrador from '../models/administrador.js';

dotenv.config();

// Materias iniciales del sistema (las que estaban hardcodeadas)
const materiasIniciales = [
  // Nivelación
  { nombre: 'Matemática Básica', codigo: 'NIV-MAT-01', semestre: 'Nivelación', creditos: 4, descripcion: 'Fundamentos de matemática' },
  { nombre: 'Física Básica', codigo: 'NIV-FIS-01', semestre: 'Nivelación', creditos: 4, descripcion: 'Introducción a la física' },
  { nombre: 'Química Básica', codigo: 'NIV-QUI-01', semestre: 'Nivelación', creditos: 4, descripcion: 'Conceptos básicos de química' },
  { nombre: 'Introducción a la Programación', codigo: 'NIV-PRO-01', semestre: 'Nivelación', creditos: 4, descripcion: 'Fundamentos de programación' },
  { nombre: 'Metodología de Estudio', codigo: 'NIV-MET-01', semestre: 'Nivelación', creditos: 2, descripcion: 'Técnicas de estudio universitario' },
  { nombre: 'Comunicación Oral y Escrita', codigo: 'NIV-COM-01', semestre: 'Nivelación', creditos: 3, descripcion: 'Habilidades de comunicación' },
  
  // Primer Semestre
  { nombre: 'Cálculo I', codigo: 'MAT-101', semestre: 'Primer Semestre', creditos: 5, descripcion: 'Límites, derivadas e integrales' },
  { nombre: 'Álgebra Lineal', codigo: 'MAT-102', semestre: 'Primer Semestre', creditos: 4, descripcion: 'Matrices, vectores y espacios vectoriales' },
  { nombre: 'Física I', codigo: 'FIS-101', semestre: 'Primer Semestre', creditos: 5, descripcion: 'Mecánica clásica' },
  { nombre: 'Programación I', codigo: 'PRO-101', semestre: 'Primer Semestre', creditos: 5, descripcion: 'Programación orientada a objetos' },
  { nombre: 'Introducción a la Ingeniería', codigo: 'ING-101', semestre: 'Primer Semestre', creditos: 3, descripcion: 'Conceptos de ingeniería' },
  { nombre: 'Comunicación Técnica', codigo: 'COM-101', semestre: 'Primer Semestre', creditos: 2, descripcion: 'Redacción técnica y presentaciones' },
  { nombre: 'Fundamentos de Computación', codigo: 'COM-102', semestre: 'Primer Semestre', creditos: 4, descripcion: 'Arquitectura de computadores' },
  
  // Segundo Semestre
  { nombre: 'Cálculo II', codigo: 'MAT-201', semestre: 'Segundo Semestre', creditos: 5, descripcion: 'Cálculo multivariable' },
  { nombre: 'Ecuaciones Diferenciales', codigo: 'MAT-202', semestre: 'Segundo Semestre', creditos: 4, descripcion: 'EDO y aplicaciones' },
  { nombre: 'Física II', codigo: 'FIS-201', semestre: 'Segundo Semestre', creditos: 5, descripcion: 'Electromagnetismo' },
  { nombre: 'Programación II', codigo: 'PRO-201', semestre: 'Segundo Semestre', creditos: 5, descripcion: 'Estructuras de datos avanzadas' },
  { nombre: 'Estructura de Datos', codigo: 'PRO-202', semestre: 'Segundo Semestre', creditos: 4, descripcion: 'Árboles, grafos y algoritmos' },
  { nombre: 'Circuitos Eléctricos', codigo: 'ELE-201', semestre: 'Segundo Semestre', creditos: 4, descripcion: 'Análisis de circuitos' },
  
  // Tercer Semestre
  { nombre: 'Cálculo III', codigo: 'MAT-301', semestre: 'Tercer Semestre', creditos: 5, descripcion: 'Cálculo vectorial' },
  { nombre: 'Métodos Numéricos', codigo: 'MAT-302', semestre: 'Tercer Semestre', creditos: 4, descripcion: 'Algoritmos numéricos' },
  { nombre: 'Electrónica Digital', codigo: 'ELE-301', semestre: 'Tercer Semestre', creditos: 4, descripcion: 'Sistemas digitales' },
  { nombre: 'Base de Datos', codigo: 'PRO-301', semestre: 'Tercer Semestre', creditos: 4, descripcion: 'Diseño y gestión de BD' },
  { nombre: 'Arquitectura de Computadores', codigo: 'COM-301', semestre: 'Tercer Semestre', creditos: 4, descripcion: 'Hardware y arquitectura' },
  { nombre: 'Sistemas Operativos', codigo: 'SIS-301', semestre: 'Tercer Semestre', creditos: 4, descripcion: 'Gestión de recursos' },
];

const migrarMaterias = async () => {
  try {
    console.log('🔄 Iniciando migración de materias...');
    
    // Conectar a MongoDB
    await mongoose.connect(process.env.MONGODB_URL);
    console.log('✅ Conectado a MongoDB');
    
    // Buscar administrador principal (el primero que exista)
    const admin = await Administrador.findOne();
    
    if (!admin) {
      console.error('❌ No se encontró ningún administrador. Ejecuta primero el servidor para crear el admin por defecto.');
      process.exit(1);
    }
    
    console.log(`👤 Usando administrador: ${admin.nombreAdministrador} (${admin.email})`);
    
    // Verificar si ya existen materias
    const materiasExistentes = await Materia.countDocuments();
    
    if (materiasExistentes > 0) {
      console.log(`⚠️ Ya existen ${materiasExistentes} materias en la base de datos.`);
      console.log('¿Deseas continuar y agregar solo las nuevas? (Las existentes no se duplicarán)');
      // En producción, aquí podrías pedir confirmación
    }
    
    let creadas = 0;
    let omitidas = 0;
    
    for (const materiaData of materiasIniciales) {
      try {
        // Verificar si ya existe (por código o nombre)
        const existe = await Materia.findOne({
          $or: [
            { codigo: materiaData.codigo },
            { nombre: materiaData.nombre }
          ]
        });
        
        if (existe) {
          console.log(`⏭️  Ya existe: ${materiaData.nombre} (${materiaData.codigo})`);
          omitidas++;
          continue;
        }
        
        // Crear nueva materia
        const nuevaMateria = new Materia({
          ...materiaData,
          creadoPor: admin._id
        });
        
        await nuevaMateria.save();
        console.log(`✅ Creada: ${nuevaMateria.nombre} (${nuevaMateria.codigo})`);
        creadas++;
        
      } catch (error) {
        console.error(`❌ Error creando ${materiaData.nombre}:`, error.message);
      }
    }
    
    console.log('\n📊 Resumen de migración:');
    console.log(`   ✅ Materias creadas: ${creadas}`);
    console.log(`   ⏭️  Materias omitidas (ya existían): ${omitidas}`);
    console.log(`   📚 Total en BD: ${await Materia.countDocuments()}`);
    
    console.log('\n✨ Migración completada exitosamente');
    
    // Cerrar conexión
    await mongoose.connection.close();
    console.log('👋 Conexión cerrada');
    
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error en la migración:', error);
    process.exit(1);
  }
};

// Ejecutar migración
migrarMaterias();