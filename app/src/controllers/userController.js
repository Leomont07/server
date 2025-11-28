import { supabase } from '../index.js'

// Obtener todos los usuarios
export const getAllUsers = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, nombre, email, rol, estatus, created_at')
      .order('created_at', { ascending: false })

    if (error) throw error
    res.status(200).json({ usuarios: data })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Cambiar rol de usuario
export const updateUserRole = async (req, res) => {
  try {
    const { id, rol } = req.body

    if (!id || !rol) {
      return res.status(400).json({ message: 'ID y nuevo rol son requeridos' })
    }

    if (!['admin', 'anfitrion', 'visitante'].includes(rol)) {
      return res.status(400).json({ message: 'Rol inválido' })
    }

    const { data, error } = await supabase
      .from('users')
      .update({ rol })
      .eq('id', id)
      .select()
      .single()

    if (error) throw error

    res.status(200).json({ message: 'Rol actualizado correctamente', usuario: data })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Cambiar estatus (activar/suspender)
export const toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params

    const { data: currentUser, error: userError } = await supabase
      .from('users')
      .select('estatus')
      .eq('id', id)
      .single()

    if (userError) throw userError
    if (!currentUser) return res.status(404).json({ message: 'Usuario no encontrado' })

    const newStatus = !currentUser.estatus

    const { data, error } = await supabase
      .from('users')
      .update({ estatus: newStatus })
      .eq('id', id)
      .select()
      .single()

    if (error) throw error

    res.status(200).json({
      message: `Usuario ${newStatus ? 'activado' : 'suspendido'} correctamente`,
      usuario: data
    })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

// Eliminar usuario
export const removeUser = async (req, res) => {
  try {
    const { id } = req.params

    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id)

    if (error) throw error

    res.status(200).json({ message: 'Usuario eliminado correctamente' })
  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}
