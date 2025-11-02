#!/bin/bash

# Obtener la IP local
LOCAL_IP=$(hostname -I | awk '{print $1}')

if [ -z "$LOCAL_IP" ]; then
  # Fallback si hostname -I no funciona
  LOCAL_IP=$(ip addr show 2>/dev/null | grep -oP 'inet \K[\d.]+' | grep -v '^127\.' | head -1)
fi

# Mostrar la IP local de forma destacada
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌐 Tu IP de red local:"
echo "     http://$LOCAL_IP:3000"
echo ""
echo "  💡 Úsala para acceder desde otros dispositivos en la misma red"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Iniciar Next.js usando npx para asegurar que use la versión local
exec npx next dev -H 0.0.0.0

