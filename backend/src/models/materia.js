// backend/src/models/materia.js
import { Schema, model } from 'mongoose';

const materiaSchema = new Schema({
  nombre: {
    type: String,
    required: true,
    trim: true,
    unique: true
  },
  codigo: {
    type: String,
    required: true,
    trim: true,
    unique: true,
    uppercase: true
  },
  semestre: {
    type: String,
    enum: [
      'Nivelación',
      'Primer Semestre',
      'Segundo Semestre',
      'Tercer Semestre',
      'Cuarto Semestre',
      'Quinto Semestre',
      'Sexto Semestre'
    ],
    required: true
  },
  creditos: {
    type: Number,
    required: true,
    min: 1,
    max: 10
  },
  descripcion: {
    type: String,
    trim: true,
    default: ''
  },
  activa: {
    type: Boolean,
    default: true
  },
  creadoPor: {
    type: Schema.Types.ObjectId,
    ref: 'Administrador',
    required: true
  },
  creadaEn: {
    type: Date,
    default: Date.now
  },
  actualizadaEn: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Índices para búsquedas rápidas
materiaSchema.index({ nombre: 1 });
materiaSchema.index({ codigo: 1 });
materiaSchema.index({ semestre: 1 });
materiaSchema.index({ activa: 1 });

// Middleware para actualizar fecha de modificación
materiaSchema.pre('save', function (next) {
  this.actualizadaEn = new Date();
  next();
});

// ✅ SOLUCIÓN: Verificar si el modelo ya existe antes de compilarlo
let Materia;
try {
  Materia = model('Materia');
} catch {
  Materia = model('Materia', materiaSchema);
}

export default Materia;