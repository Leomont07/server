# ... (Fase de construcción)
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production --silent && npm cache clean --force
COPY . . 
# ...
# (Fase de ejecución)
FROM node:20-alpine
# ...
WORKDIR /app
COPY --from=builder /app ./
CMD ["npm", "start"]