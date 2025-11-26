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

  // ✅ Horarios específicos del turno (20 min máximo)
  horaInicio: { type: String, required: true },
  horaFin: { type: String, required: true },
  
  // ✅ Referencia al bloque de disponibilidad del docente
  bloqueDocenteId: {
    type: Schema.Types.ObjectId,
    ref: "disponibilidadDocente",
    required: false
  },

  // ✅ CAMPOS PARA REAGENDAMIENTO
  motivoReagendamiento: { 
    type: String, 
    default: null 
  },
  reagendadaPor: {
    type: String,
    enum: ['Estudiante', 'Docente', null],
    default: null
  },
  fechaReagendamiento: {
    type: Date,
    default: null
  },

  estado: {
    type: String,
    enum: [
      "pendiente",
      "confirmada",
      "rechazada",
      "cancelada_por_estudiante",
      "cancelada_por_docente", 
      "finalizada",
      "no_asiste",
      "expirada"  // ✅ NUEVO ESTADO
    ],
    default: "pendiente"
  },

  motivoRechazo: { 
    type: String, 
    default: null 
  },

  asistenciaEstudiante: { type: Boolean, default: null },
  motivoCancelacion: { type: String, default: null },
  observacionesDocente: { type: String, default: null },

  // NUEVOS CAMPOS PARA CONTROL DE RECORDATORIOS
  recordatorio24hEnviado: { 
    type: Boolean, 
    default: false 
  },
  recordatorio3hEnviado: { 
    type: Boolean, 
    default: false 
  },

  creadaEn: { type: Date, default: Date.now },
  actualizadaEn: { type: Date, default: Date.now }
});

// Índice compuesto para búsquedas rápidas de solapamiento
tutoriaSchema.index({ docente: 1, fecha: 1, estado: 1 });
tutoriaSchema.index({ estudiante: 1, fecha: 1 });

// Middleware para actualizar fecha de modificación
tutoriaSchema.pre("save", function (next) {
  this.actualizadaEn = new Date();
  next();
});

export default model("Tutoria", tutoriaSchema);