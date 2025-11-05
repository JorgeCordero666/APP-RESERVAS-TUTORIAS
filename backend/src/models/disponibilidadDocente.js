// backend/src/models/disponibilidadDocente.js - VERSIÓN CORREGIDA
import mongoose, { Schema, model } from "mongoose";

const disponibilidadSchema = new Schema({
  docente: { 
    type: Schema.Types.ObjectId, 
    ref: "Docente", 
    required: true,
    index: true // Mejorar búsquedas
  },
  diaSemana: {
    type: String,
    enum: ["lunes", "martes", "miércoles", "jueves", "viernes"],
    required: true
  },
  materia: {
    type: String,
    trim: true,
    required: true, // ✅ CAMBIO: Ahora es obligatorio
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
      _id: false // No generar IDs automáticos para sub-documentos
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

// ✅ Validación personalizada: hora fin debe ser mayor que hora inicio
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