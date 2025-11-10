// backend/src/models/tutorias.js - VERSIÓN CON ACEPTAR/RECHAZAR
import mongoose, { Schema, model } from "mongoose";

const tutoriaSchema = new Schema({
  estudiante: { 
    type: Schema.Types.ObjectId, 
    ref: "Estudiante", 
    required: true 
  },
  docente: { 
    type: Schema.Types.ObjectId, 
    ref: "Docente", 
    required: true 
  },

  fecha: { type: String, required: true },

  // Bloque de tiempo elegido
  horaInicio: { type: String, required: true },
  horaFin: { type: String, required: true },

  estado: {
    type: String,
    enum: [
      "pendiente",               // ✅ Recién creada por estudiante
      "confirmada",              // ✅ Aceptada por docente
      "rechazada",               // ✅ NUEVO: Rechazada por docente
      "cancelada_por_estudiante",
      "cancelada_por_docente", 
      "finalizada",
      "no_asiste"
    ],
    default: "pendiente"
  },

  // ✅ NUEVO: Motivo de rechazo
  motivoRechazo: { 
    type: String, 
    default: null 
  },

  asistenciaEstudiante: { type: Boolean, default: null },
  motivoCancelacion: { type: String, default: null },
  observacionesDocente: { type: String, default: null },

  creadaEn: { type: Date, default: Date.now },
  actualizadaEn: { type: Date, default: Date.now }
});

// Middleware para actualizar fecha de modificación
tutoriaSchema.pre("save", function (next) {
  this.actualizadaEn = new Date();
  next();
});

export default model("Tutoria", tutoriaSchema);