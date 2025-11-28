# Fase de construcción: Builder (Para instalar las dependencias)
FROM node:20-alpine AS builder

WORKDIR /app

# 1. Copia solo los archivos de definición de dependencias
# (Asume que package.json y package-lock.json están en ./app)
COPY package*.json ./

# 2. Instala las dependencias de producción
RUN npm install --only=production

# 3. Copia el código fuente de la aplicación (la carpeta donde está index.js)
# NOTA: Usamos el . para copiar todo el contenido del contexto
COPY . . 


# ----------------------------------------
# Fase de ejecución: Final (Imagen limpia)
FROM node:20-alpine

# El puerto de la aplicación
ENV PORT=3000
EXPOSE 3000

# Crea un usuario no root para seguridad
RUN adduser -D appuser
USER appuser

WORKDIR /app

# Copia TODOS los archivos (incluyendo node_modules y el código fuente)
# desde la fase 'builder' al directorio de trabajo de la fase final.
COPY --from=builder /app ./

# Comando de inicio: npm start requiere que index.js esté en el WORKDIR /app
CMD ["npm", "start"]