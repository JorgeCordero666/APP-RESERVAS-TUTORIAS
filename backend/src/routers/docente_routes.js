import { Router } from 'express';
import { 
  registrarDocente, 
  listarDocentes, 
  detalleDocente,
  eliminarDocente, 
  actualizarDocente, 
  loginDocente, 
  perfilDocente,
  crearNuevoPasswordDocente,
  comprobarTokenPasswordDocente,
  recuperarPasswordDocente,
  actualizarPerfilDocente,      
  actualizarPasswordDocente,
  cambiarPasswordObligatorio      
} from '../controllers/docente_controller.js';
import { loginOAuthDocente } from "../controllers/sesion_google_correo_controller.js";
import { verificarTokenJWT } from '../middlewares/JWT.js';
import verificarRol from "../middlewares/rol.js";

// 🔹 Importar modelos necesarios
import Docente from '../models/docente.js';
import Materia from '../models/Materia.js';

const routerDocente = Router();

// ========== RUTAS PÚBLICAS ==========

routerDocente.post('/docente/login', loginDocente);
routerDocente.post('/docente/login-oauth', loginOAuthDocente);
routerDocente.post('/docente/recuperarpassword', recuperarPasswordDocente);
routerDocente.get('/docente/recuperarpassword/:token', comprobarTokenPasswordDocente);
routerDocente.post('/docente/nuevopassword/:token', crearNuevoPasswordDocente);
routerDocente.post('/docente/cambiar-password-obligatorio', verificarTokenJWT, cambiarPasswordObligatorio);

// ========== RUTAS PRIVADAS - DOCENTE ==========

routerDocente.get('/docente/perfil', verificarTokenJWT, verificarRol(["Docente"]), perfilDocente);
routerDocente.put('/docente/perfil/:id', verificarTokenJWT, verificarRol(["Docente", "Administrador"]), actualizarPerfilDocente);
routerDocente.put('/docente/actualizarpassword/:id', verificarTokenJWT, verificarRol(["Docente"]), actualizarPasswordDocente);

// ✅ NUEVA RUTA: Validar y sincronizar materias del docente
routerDocente.get('/docente/validar-materias/:docenteId',
  verificarTokenJWT,
  verificarRol(["Docente", "Administrador"]),
  async (req, res) => {
    try {
      const { docenteId } = req.params;

      // Buscar docente
      const docente = await Docente.findById(docenteId);
      if (!docente) {
        return res.status(404).json({ msg: 'Docente no encontrado' });
      }

      // Materias activas en la BD
      const materiasActivas = await Materia.find({ activa: true }).select('nombre');
      const nombresMateriasActivas = materiasActivas.map(m => m.nombre);

      // Filtrar asignaturas del docente que sigan activas
      const asignaturasValidas = docente.asignaturas.filter(asignatura =>
        nombresMateriasActivas.includes(asignatura)
      );

      // Actualizar si hay cambios
      const huboCambios = asignaturasValidas.length !== docente.asignaturas.length;
      if (huboCambios) {
        docente.asignaturas = asignaturasValidas;
        await docente.save();
        console.log(`✅ Materias del docente ${docente.nombreDocente} sincronizadas`);
      }

      res.json({
        materiasValidas: asignaturasValidas,
        materiasActivas: nombresMateriasActivas,
        fueronEliminadas: huboCambios
      });
    } catch (error) {
      console.error('Error validando materias:', error);
      res.status(500).json({ msg: 'Error del servidor' });
    }
  }
);

// ========== RUTAS PRIVADAS - ADMINISTRADOR ==========

routerDocente.post("/docente/registro", verificarTokenJWT, verificarRol(["Administrador"]), registrarDocente);
routerDocente.get("/docentes", verificarTokenJWT, verificarRol(["Administrador", "Estudiante"]), listarDocentes);
routerDocente.get("/docente/:id", verificarTokenJWT, detalleDocente);
routerDocente.delete("/docente/eliminar/:id", verificarTokenJWT, verificarRol(["Administrador"]), eliminarDocente);
routerDocente.put("/docente/actualizar/:id", verificarTokenJWT, verificarRol(["Administrador"]), actualizarDocente);

export default routerDocente;
