// backend/src/models/disponibilidadDocente.js - VERSIÓN CORREGIDA
import mongoose, { Schema, model } from "mongoose";

const disponibilidadSchema = new Schema({
  docente: { 
    type: Schema.Types.ObjectId, 
    ref: "Docente", 
    required: true,
    index: true
  },
  diaSemana: {
    type: String,
    enum: ["lunes", "martes", "miércoles", "jueves", "viernes"],
    required: true,
    lowercase: true, // ✅ Asegurar minúsculas siempre
    trim: true
  },
  materia: {
    type: String,
    trim: true,
    required: true,
    index: true
  },
  bloques: [
    {
      horaInicio: { 
        type: String, 
        required: true,
        validate: {
          validator: function(v) {
            return /^([01]\d|2[0-3]):([0-5]\d)$/.test(v);
          },
          message: 'Formato de hora inválido (HH:MM)'
        }
      }, 
      horaFin: { 
        type: String, 
        required: true,
        validate: {
          validator: function(v) {
            return /^([01]\d|2[0-3]):([0-5]\d)$/.test(v);
          },
          message: 'Formato de hora inválido (HH:MM)'
        }
      },
      _id: false
    }
  ]
}, {
  timestamps: true
});

// ✅ Índice compuesto para evitar duplicados
disponibilidadSchema.index(
  { docente: 1, diaSemana: 1, materia: 1 }, 
  { unique: true }
);

// ✅ Middleware para normalizar días ANTES de guardar
disponibilidadSchema.pre('save', function(next) {
  if (this.diaSemana) {
    // Normalizar: quitar acentos, espacios, minúsculas
    this.diaSemana = this.diaSemana
      .toLowerCase()
      .trim()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, ''); // Quitar acentos
    
    // Mapeo explícito
    const mapaValidos = {
      'lunes': 'lunes',
      'martes': 'martes',
      'miercoles': 'miércoles',
      'miércoles': 'miércoles',
      'jueves': 'jueves',
      'viernes': 'viernes'
    };
    
    this.diaSemana = mapaValidos[this.diaSemana] || this.diaSemana;
  }
  next();
});

// ✅ Validación: hora fin > hora inicio
disponibilidadSchema.path('bloques').validate(function(bloques) {
  return bloques.every(bloque => {
    const [hIni, mIni] = bloque.horaInicio.split(':').map(Number);
    const [hFin, mFin] = bloque.horaFin.split(':').map(Number);
    const inicioMinutos = hIni * 60 + mIni;
    const finMinutos = hFin * 60 + mFin;
    return finMinutos > inicioMinutos;
  });
}, 'La hora de fin debe ser mayor que la hora de inicio');

export default model("disponibilidadDocente", disponibilidadSchema);