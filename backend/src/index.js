import app from './server.js';
import connection from './database.js';
import { marcarTutoriasExpiradas } from './controllers/tutorias_controller.js';

connection();

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`✅ Server ok on http://0.0.0.0:${PORT}`);
  
  // ✅ Marcar tutorías expiradas al iniciar
  await marcarTutoriasExpiradas();
  
  // ✅ Ejecutar cada hora
  setInterval(marcarTutoriasExpiradas, 60 * 60 * 1000);
});