import e from 'express'
import { supabase } from '../index.js'

export const add = async (req, res) => {
  try {
    const { nombre, descripcion, precio, idUsuario, tipo, estatus,
            subtipo, numHabitaciones, numCuartos, numPisos,
            cantidad,duracionHoras
          } = req.body

    if (!nombre || !descripcion || !precio || !tipo || !estatus) {
      return res.status(400).json({ message: 'Los campos nombre, descripcion, precio, tipo y estatus son obligatorios'})
    }

    const serviceData = { 
      nombre, descripcion, precio, tipo, idUsuario, estatus,
      subtipo, numHabitaciones, numCuartos, numPisos,
      cantidad,
      duracionHoras
    }
    
    Object.keys(serviceData).forEach(key => 
      (serviceData[key] === null || serviceData[key] === undefined || serviceData[key] === '') && delete serviceData[key]
    );

    const { data, error } = await supabase
      .from('service')
      .insert([serviceData])
      .select()
      .single()

    if (error) throw error

    res.status(201).json({ servicio: data })

  } catch (error) {
    res.status(500).json({ message: error.message })
  }
}

export const edit = async (req, res) => {
    try {
        const { id } = req.params
        const { 
            nombre, descripcion, precio, tipo,
            subtipo, numHabitaciones, numCuartos, numPisos,
            cantidad,
            duracionHoras
        } = req.body


        if (!nombre || !descripcion || !precio || !tipo) {
            return res.status(400).json({ message: 'Los campos nombre, descripcion, precio y tipo son obligatorios' })
        }

        const serviceData = { 
            nombre, descripcion, precio, tipo,
            subtipo, numHabitaciones, numCuartos, numPisos,
            cantidad,
            duracionHoras
        }
        
        Object.keys(serviceData).forEach(key => 
          (serviceData[key] === null || serviceData[key] === undefined || serviceData[key] === '') && delete serviceData[key]
        );

        const { data, error } = await supabase
            .from('service')
            .update(serviceData)
            .eq('id', id)
            .select()
            .single()

        if (error) throw error

        res.status(200).json({ servicio: data })

    }
    catch (error) {
        res.status(500).json({ message: error.message })
    }
}

export const remove = async (req, res) => {
  const { id } = req.params

  try {
    const { error } = await supabase
      .from('service')
      .update({ estatus: 0 })
      .eq('id', id)

    if (error) throw error
    res.json({ message: 'Servicio eliminado correctamente' })
  } catch (error) {
    res.status(400).json({ error: error.message })
  }
}


export const getAllServices = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('service')
            .select('*')
            .eq('estatus', 1)

        if (error) throw error

        res.status(200).json({ servicios: data })

    } catch (error) {
        res.status(500).json({ message: error.message })
    }       
}

export const getServiceById = async (req, res) => {
    try {
        const { id } = req.params
        const { data, error } = await supabase
            .from('service')
            .select('*')
            .eq('id', id)
            .single()

        if (error) throw error

        res.status(200).json({ servicio: data })
        console.log(data)

    } catch (error) {
        res.status(500).json({ message: error.message })
        console.log(error)
    }
}

export const getServicesByUserId = async (req, res) => {
    try {
        const { idUsuario } = req.params
        const { data, error } = await supabase
            .from('service')
            .select('*')
            .eq('idUsuario', idUsuario)
            .eq('estatus', 1)
            
        if (error) throw error

        res.status(200).json({ servicios: data })

    } catch (error) {
        res.status(500).json({ message: error.message })
    }
}