#!/usr/bin/env bash
# Descarga el plugin sonar-flutter (soporte Dart/Flutter para SonarQube 10.x)
# Ejecutar UNA VEZ antes de levantar docker-compose.sonar.yml

set -e

PLUGIN_VERSION="0.4.0"
PLUGIN_JAR="sonar-flutter-${PLUGIN_VERSION}.jar"
PLUGIN_URL="https://github.com/insideapp-oss/sonar-flutter/releases/download/${PLUGIN_VERSION}/${PLUGIN_JAR}"
PLUGINS_DIR="$(dirname "$0")/plugins"

if [ -f "${PLUGINS_DIR}/${PLUGIN_JAR}" ]; then
  echo "Plugin ya descargado: ${PLUGINS_DIR}/${PLUGIN_JAR}"
  exit 0
fi

echo "Descargando sonar-flutter ${PLUGIN_VERSION}..."
curl -L --fail --output "${PLUGINS_DIR}/${PLUGIN_JAR}" "${PLUGIN_URL}"
echo "Plugin descargado correctamente en sonar/plugins/${PLUGIN_JAR}"
echo "Ahora puedes levantar SonarQube: docker-compose -f docker-compose.sonar.yml up -d"
