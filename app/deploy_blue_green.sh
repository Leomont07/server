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
IMAGE_NAME="ghcr.io/$(echo $GITHUB_REPOSITORY | tr '[:upper:]' '[:lower:]')"
NEW_IMAGE="$IMAGE_NAME:$NEW_TAG" [cite: 8, 9]

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

# === FIX DE DIAGNÓSTICO: MOSTRAR LOGS AL INICIAR ===
echo "Mostrando logs de inicio del contenedor $INACTIVE_SLOT por 5 segundos..."
docker logs "$INACTIVE_SLOT" --follow &
PID=$!
sleep 5
kill $PID || true

# 6. Health Check (simulado con un sleep)
echo "Realizando Health Check en $INACTIVE_SLOT (Puerto $INACTIVE_PORT)..."
echo "Esperando 10s para que el contenedor inicie..."
sleep 10

# 7. Realizar el switch de tráfico en Nginx
echo "Cambiando el tráfico de Nginx a $INACTIVE_SLOT"
# Eliminar el enlace simbólico anterior y crear uno nuevo
sudo ln -snf "$INACTIVE_CONF" "$NGINX_CONF_DIR/bg_switch/current_upstream.conf"
sudo systemctl reload nginx

# 8. Actualizar el estado de producción en .env
echo "Actualizando estado. Nuevo slot de producción: $INACTIVE_SLOT"
echo "CURRENT_PRODUCTION=$INACTIVE_SLOT" > "$ENV_FILE"