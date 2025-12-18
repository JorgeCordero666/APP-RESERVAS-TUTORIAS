    // MODELO MODIFICADO PARA INCLUIR AUTENTICACIÓN CON GOOGLE Y MICROSOFT

    import {Schema, model} from 'mongoose'
    import bcrypt from 'bcryptjs'

    const estudiantesSchema = new Schema({
        nombreEstudiante: {
            type: String,
            required: true,
        },
        telefono: {
            type: String,
            trim: true,
            default: null,
        }, 
        emailEstudiante: {
            type: String,
            required: true,
            trim: true,
            unique: true,
        }, 
        password: {
            type: String,
            required: function () {
            return !this.isOAuth;  // obligatorio solo si NO es OAuth
            },
        },
        isOAuth: {
            type: Boolean,
            default: false,
        },
        oauthProvider: {
            type: String,
            enum: ['google', 'microsoft', null],
            default: null,
        },
        status: {
            type: Boolean,
            default: true,
        },
        token: {
            type: String,
            //default: null,
        },
        confirmEmail: {
            type: Boolean,
            default: false,
        },
        rol: {
            type: String,
            default: "Estudiante"
        },
        fotoPerfil: {
        type: String,
        default: "https://cdn-icons-png.flaticon.com/512/4715/4715329.png"  //Enviar un icono por defecto
        },
        fotoPerfilID: { // ID de Cloudinary para poder eliminarla/reemplazarla
        type: String
        }
    }, {
        timestamps: true,
    })

    //Método para cifrar password 
    estudiantesSchema.methods.encrypPassword = async function(password) {
        if (this.isOAuth) return null;
        const salt = await bcrypt.genSalt(10)
        return await bcrypt.hash(password, salt)
    }

    //Método para verificar password 
    estudiantesSchema.methods.matchPassword = async function(password) {
        if (this.isOAuth) return false;
        return await bcrypt.compare(password, this.password)
    }

    estudiantesSchema.methods.crearToken = function() {
        const tokenGenerado = this.token = Math.random().toString(32).slice(2)
        return tokenGenerado
    }

    export default model('Estudiante', estudiantesSchema)
