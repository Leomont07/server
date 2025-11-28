#!/bin/bash
set -e # Termina el script si hay un error

NEW_TAG=$1
########################################
if [ -z "$NEW_TAG" ]; then
    echo "Error: No se proporcionó ningún tag de imagen."
    exit 1
fi
########################################

# Convertir a minúsculas para Docker/GHCR (CORRECCIÓN)
LOWERCASE_REPO=$(echo "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')
IMAGE_NAME="ghcr.io/$LOWERCASE_REPO"
NEW_IMAGE="$IMAGE_NAME:$NEW_TAG"

echo "--- Inicio de Despliegue Blue-Green ---"

APP_DIR="/home/${USER}/app" # Usamos ${USER} o el valor que estés usando en el script
ENV_FILE="$APP_DIR/.env"
NGINX_CONF_DIR="/etc/nginx"

# 1. Establecer el estado inicial si el archivo .env no existe
if [ ! -f "$ENV_FILE" ]; then
    echo "CURRENT_PRODUCTION=green" > "$ENV_FILE"
fi

source "$ENV_FILE"

# 2. Determinar el slot inactivo (al que vamos a desplegar)
if [ "$CURRENT_PRODUCTION" == "blue" ]; then
    ACTIVE_SLOT="blue"
    INACTIVE_SLOT="green"
    INACTIVE_PORT="3001"
    INACTIVE_CONF="$NGINX_CONF_DIR/app/nginx/green.conf"
else
    ACTIVE_SLOT="green"
    INACTIVE_SLOT="blue"
    INACTIVE_PORT="3000"
    INACTIVE_CONF="$NGINX_CONF_DIR/app/nginx/blue.conf"
fi

echo "Ambiente Actual (ACTIVO): $ACTIVE_SLOT (Puerto $(if [ "$ACTIVE_SLOT" == "blue" ]; then echo 3000; else echo 3001; fi))"
echo "Ambiente Siguiente (NUEVO): $INACTIVE_SLOT (Puerto $INACTIVE_PORT)"

# 3. Pull de la nueva imagen
echo "1. Haciendo pull de la nueva imagen: $NEW_IMAGE"
docker pull "$NEW_IMAGE"

# 4. Detener y eliminar el contenedor inactivo anterior (si existe)
echo "2. Limpiando contenedor anterior de $INACTIVE_SLOT (si existe)" 
docker stop "$INACTIVE_SLOT" || true
docker rm "$INACTIVE_SLOT" || true

# 5. Iniciar el nuevo contenedor
echo "3. Iniciando nuevo contenedor: $INACTIVE_SLOT en el puerto $INACTIVE_PORT..."
CONTAINER_ID=$(docker run -d --name "$INACTIVE_SLOT" \
    --network blue_green_network \
    -p "$INACTIVE_PORT:3000" \
    -e "APP_COLOR=$INACTIVE_SLOT" \
    --restart unless-stopped \
    "$NEW_IMAGE")
echo $CONTAINER_ID

# 6. DIAGNÓSTICO CRÍTICO: Revisar estado y logs del contenedor
echo "4. Esperando 10s para el diagnóstico de inicio..."
sleep 10

# Obtener el estado del contenedor: running, exited, etc.
STATUS=$(docker inspect -f '{{.State.Status}}' "$INACTIVE_SLOT" 2>/dev/null)

echo "--- LOGS DEL CONTENEDOR $INACTIVE_SLOT ---"
# Esto nos mostrará el error real (e.g., npm start error)
docker logs "$INACTIVE_SLOT"
echo "--- FIN DE LOGS ---"

if [ "$STATUS" != "running" ]; then
    echo "ERROR CRÍTICO: El contenedor $INACTIVE_SLOT no se está ejecutando (Estado: $STATUS). ABORTANDO DESPLIEGUE."
    docker stop "$INACTIVE_SLOT" || true
    docker rm "$INACTIVE_SLOT" || true
    exit 1 
fi

# 7. Realizar Health Check (Sencillo, ya que el diagnóstico ya se hizo)
echo "5. Contenedor activo. Realizando Health Check final (20 segundos)..."
for i in {1..20}; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$INACTIVE_PORT/health")
    if [ "$RESPONSE" -eq 200 ]; then
        echo "Health Check exitoso!"
        HEALTH_CHECK_OK=true
        break
    fi
    sleep 1
done

if [ "$HEALTH_CHECK_OK" != "true" ]; then
    echo "ERROR: Health Check fallido para $INACTIVE_SLOT. El contenedor está corriendo pero no responde."
    echo "ERROR DE DESPLIEGUE. Manteniendo el ambiente $ACTIVE_SLOT ACTIVO."
    exit 1
fi

# 8. Realizar el switch de tráfico en Nginx
echo "6. Cambiando el tráfico de Nginx a $INACTIVE_SLOT"
# Eliminar el enlace simbólico anterior y crear uno nuevo
sudo ln -snf "$INACTIVE_CONF" "$NGINX_CONF_DIR/bg_switch/current_upstream.conf"
sudo systemctl reload nginx

# 9. Actualizar el estado de producción en .env
echo "7. Actualizando estado. Nuevo slot de producción: $INACTIVE_SLOT"
echo "CURRENT_PRODUCTION=$INACTIVE_SLOT" > "$ENV_FILE"