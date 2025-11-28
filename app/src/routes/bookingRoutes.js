import express from 'express'
import { add, getBookById, getBookingsByHostId, getBookingsByUserId, remove } from '../controllers/bookingController.js'

const router = express.Router()

router.post('/add', add)
router.delete('/remove/:id', remove)
router.get('/getById/:id', getBookById)
router.get('/getByUser/:idUsuario', getBookingsByUserId)
router.get('/getByHost/:idHost', getBookingsByHostId)

export default router
