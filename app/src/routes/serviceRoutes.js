import express from 'express'
import { add, edit, getAllServices, getServiceById, getServicesByUserId, remove } from '../controllers/serviceController.js'

const router = express.Router()

router.post('/add', add)
router.put('/edit/:id', edit)
router.put('/remove/:id', remove)
router.get('/getAll', getAllServices)
router.get('/getById/:id', getServiceById)
router.get('/getByUser/:idUsuario', getServicesByUserId)

export default router
