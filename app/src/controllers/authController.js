import bcrypt from 'bcryptjs'
import { supabase } from '../index.js'
import { generateToken } from '../utils/generateToken.js'

export const register = async (req, res) => {
  try {
    const { nombre, email, password, tipo } = req.body

    if (!nombre || !email || !password || !tipo) {
      return res.status(400).json({ message: 'Todos los campos son obligatorios' })
    }

    // ¿Ya existe ese email?
    const { data: existingUser } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single()

    if (existingUser) {
      return res.status(400).json({ message: 'El correo ya está registrado' })
    }

    // Hash de contraseña
    const hashedPassword = await bcrypt.hash(password, 10)

    // Insertar usuario nuevo
    const { data, error } = await supabase
      .from('users')
      .insert([{ nombre, email, password: hashedPassword, tipo }])
      .select()
      .single()

    if (error) throw error

    // Generar token
    const token = generateToken(data.id)

    res.status(201).json({ user: data, token })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

export const login = async (req, res) => {
  try {
    const { email, password } = req.body
    
    if (!email || !password) {
      return res.status(400).json({ message: 'Faltan campos' })
    }

    // Buscar usuario
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email)
      .single()

    if (error || !user) {
      return res.status(400).json({ message: 'Usuario no encontrado' })
    }

    // Verificar contraseña
    const isMatch = await bcrypt.compare(password, user.password)
    if (!isMatch) {
      return res.status(401).json({ message: 'Contraseña incorrecta' })
    }

    // Generar token
    const token = generateToken(user.id)

    res.json({ user, token })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}
