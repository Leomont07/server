#!/bin/bash
set -e # Termina el script si hay un error

NEW_TAG=$1
########################################
if [ -z "$NEW_TAG" ]; then
    echo "Error: No se proporcionó ningún tag de imagen." [cite: 5, 6]
    exit 1
fi
########################################

# Convertir a minúsculas para Docker/GHCR
LOWERCASE_REPO=$(echo "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')
IMAGE_NAME="ghcr.io/$LOWERCASE_REPO"
NEW_IMAGE="$IMAGE_NAME:$NEW_TAG"

APP_DIR="/home/deployer/app"
ENV_FILE="$APP_DIR/.env"
NGINX_CONF_DIR="/etc/nginx"

# 1. Establecer el estado inicial si el archivo .env no existe
if [ ! -f "$ENV_FILE" ]; then
    echo "CURRENT_PRODUCTION=green" > "$ENV_FILE" [cite: 14, 15, 16]
fi

source "$ENV_FILE" [cite: 19]

# 2. Determinar el slot inactivo (al que vamos a desplegar)
if [ "$CURRENT_PRODUCTION" == "blue" ]; then [cite: 21]
    INACTIVE_SLOT="green" [cite: 22]
    INACTIVE_PORT="3001" [cite: 23]
    INACTIVE_CONF="$NGINX_CONF_DIR/app/nginx/green.conf"
else
    INACTIVE_SLOT="blue" [cite: 26]
    INACTIVE_PORT="3000" [cite: 27]
    INACTIVE_CONF="$NGINX_CONF_DIR/app/nginx/blue.conf"
fi [cite: 28, 29]

echo "Desplegando en el slot inactivo: $INACTIVE_SLOT" [cite: 31]

# 3. Pull de la nueva imagen
echo "Haciendo pull de la nueva imagen: $NEW_IMAGE" [cite: 33]
docker pull "$NEW_IMAGE"

# 4. Detener y eliminar el contenedor inactivo anterior (si existe)
echo "Deteniendo y eliminando contenedor $INACTIVE_SLOT (si existe)" 
docker stop "$INACTIVE_SLOT" || true
docker rm "$INACTIVE_SLOT" || true

# 5. Iniciar el nuevo contenedor
echo "Iniciando nuevo contenedor: $INACTIVE_SLOT en el puerto $INACTIVE_PORT..."
docker run -d --name "$INACTIVE_SLOT" \
    --network blue_green_network \
    -p "$INACTIVE_PORT:3000" \
    -e "APP_COLOR=$INACTIVE_SLOT" \
    --restart unless-stopped \
    "$NEW_IMAGE"

# 5.1. DIAGNÓSTICO CRÍTICO: Esperar 10s y revisar el estado y logs del contenedor
echo "Esperando 10s para que el contenedor inicie y capturando logs..."
sleep 10

# Obtener el estado del contenedor: running, exited, etc.
STATUS=$(docker inspect -f '{{.State.Status}}' "$INACTIVE_SLOT")
echo "Estado actual del contenedor $INACTIVE_SLOT: $STATUS"

# Mostrar logs completos para diagnosticar el fallo
echo "--- LOGS DEL CONTENEDOR $INACTIVE_SLOT ---"
docker logs "$INACTIVE_SLOT"
echo "--- FIN DE LOGS ---"

if [ "$STATUS" != "running" ]; then
    echo "ERROR CRÍTICO: El contenedor $INACTIVE_SLOT no se está ejecutando. ABORTANDO."
    # Si el contenedor falla al iniciar, eliminamos el contenedor para evitar basura
    docker stop "$INACTIVE_SLOT" || true
    docker rm "$INACTIVE_SLOT" || true
    exit 1
fi

# 6. DIAGNÓSTICO CRÍTICO: Esperar 10s y revisar el estado y logs del contenedor
echo "Esperando 10s para que el contenedor inicie (o falle) y capturando logs..."
sleep 10

# Obtener el estado del contenedor: running, exited, etc.
STATUS=$(docker inspect -f '{{.State.Status}}' "$INACTIVE_SLOT" 2>/dev/null)

echo "--- LOGS DEL CONTENEDOR $INACTIVE_SLOT ---"
# Mostramos los logs completos para ver el error de la aplicación (npm start)
docker logs "$INACTIVE_SLOT"
echo "--- FIN DE LOGS ---"

if [ "$STATUS" != "running" ]; then
    echo "ERROR CRÍTICO: El contenedor $INACTIVE_SLOT no se está ejecutando (Estado: $STATUS). Abortando despliegue."
    # Si falla, salimos para evitar la conmutación de Nginx
    docker stop "$INACTIVE_SLOT" || true
    docker rm "$INACTIVE_SLOT" || true
    exit 1 
fi

# 7. Realizar el switch de tráfico en Nginx
echo "Contenedor $INACTIVE_SLOT en ejecución. Cambiando el tráfico de Nginx..."
# Eliminar el enlace simbólico anterior y crear uno nuevo
sudo ln -snf "$INACTIVE_CONF" "$NGINX_CONF_DIR/bg_switch/current_upstream.conf"
sudo systemctl reload nginx

# 8. Actualizar el estado de producción en .env
echo "Actualizando estado. Nuevo slot de producción: $INACTIVE_SLOT"
echo "CURRENT_PRODUCTION=$INACTIVE_SLOT" > "$ENV_FILE"