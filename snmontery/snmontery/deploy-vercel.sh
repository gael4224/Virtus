#!/bin/bash
echo "🚀 Deploying to Vercel..."
echo ""
echo "Si no estás autenticado, primero ejecuta: npx vercel login"
echo "Luego ejecuta este script de nuevo."
echo ""
read -p "¿Estás autenticado? (y/n): " authenticated
if [ "$authenticated" = "y" ]; then
    echo ""
    echo "Iniciando deployment..."
    npx vercel --yes
else
    echo ""
    echo "Por favor ejecuta primero: npx vercel login"
fi
