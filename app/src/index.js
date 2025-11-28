import express from 'express'
import dotenv from 'dotenv'
import cors from 'cors'
import { createClient } from '@supabase/supabase-js'
import authRoutes from './routes/authRoutes.js'
import serviceRoutes from'./routes/serviceRoutes.js'
import bookingRoutes from './routes/bookingRoutes.js'

dotenv.config()
const app = express()
app.use(cors({ origin: '*', credentials: true }))
app.use(express.json())

// Conexión Supabase
export const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
)

// Rutas
app.use('/api/auth', authRoutes)
app.use('/api/service', serviceRoutes)
app.use('/api/booking', bookingRoutes)

app.listen(port, '0.0.0.0', () => { 
  console.log(`Aplicación Node.js escuchando en el puerto ${port}`);
});