# Fase de construcción (para reducir el tamaño de la imagen final)
FROM node:20-alpine AS builder

WORKDIR /app

# Copia los archivos de definición de dependencias
COPY package*.json ./

# Instala las dependencias de producción
RUN npm install --only=production

# Copia el código fuente (src, .env, etc.)
COPY . .

# Comando de inicio
# Asumiendo que tu archivo principal está en src/index.js o similar
CMD ["npm", "start"] 


# ----------------------------------------
# Fase de ejecución (Imagen final más limpia)
FROM node:20-alpine

# El puerto de la aplicación debe ser consistente con lo que se define en el script
ENV PORT=3000
EXPOSE 3000

# Crea un usuario no root para seguridad
RUN adduser -D appuser
USER appuser

WORKDIR /app

# Copia los archivos de la fase de construcción
COPY --from=builder /app ./

# Tu aplicación inicia aquí (puede variar, ajusta según tu package.json)
CMD ["npm", "start"]