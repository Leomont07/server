import e from 'express'
import {
  getAllUsers,
  updateUserRole,
  toggleUserStatus,
  removeUser
} from '../controllers/userController.js'

const router = e.Router()

router.get('/', getAllUsers)                 // Obtener todos los usuarios
router.put('/role', updateUserRole)          // Cambiar rol
router.put('/status/:id', toggleUserStatus)  // Activar/Suspender
router.delete('/:id', removeUser)            // Eliminar usuario

export default router
