// backend/src/models/disponibilidadDocente.js - MODIFICADO
import mongoose, { Schema, model } from "mongoose";

const disponibilidadSchema = new Schema({
  docente: { 
    type: Schema.Types.ObjectId, 
    ref: "Docente", 
    required: true 
  },
  diaSemana: {
    type: String,
    enum: ["lunes", "martes", "miércoles", "jueves", "viernes"],
    required: true
  },
  // ⭐ NUEVO: Agregar materia (opcional para mantener compatibilidad)
  materia: {
    type: String,
    trim: true,
    default: null // null = disponibilidad general (sin materia específica)
  },
  bloques: [
    {
      horaInicio: { type: String, required: true }, 
      horaFin: { type: String, required: true },   
    }
  ]
}, {
  timestamps: true
});

// ⭐ NUEVO: Índice compuesto para evitar duplicados
// Permite múltiples registros por docente+día si tienen diferente materia
disponibilidadSchema.index({ docente: 1, diaSemana: 1, materia: 1 }, { unique: true });

export default model("disponibilidadDocente", disponibilidadSchema);