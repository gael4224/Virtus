#!/bin/bash
echo "=== Verificación de Despliegue de Contratos ==="
echo ""

cd "$(dirname "$0")/snmontery/snmontery" || exit 1

echo "1. Verificando .env.local:"
if [ -f .env.local ]; then
    echo "   ✅ Archivo .env.local existe"
    if grep -q "NEXT_PUBLIC_CONTRATO_ADDRESS" .env.local; then
        ADDR=$(grep "NEXT_PUBLIC_CONTRATO_ADDRESS" .env.local | cut -d'=' -f2 | tr -d ' ')
        if [ "$ADDR" != "" ] && [ "$ADDR" != "0x0000000000000000000000000000000000000000" ]; then
            echo "   ✅ Dirección configurada: $ADDR"
            echo "   🔍 Verifica en el explorador: https://sepolia-explorer.arbitrum.io/address/$ADDR"
        else
            echo "   ❌ Dirección vacía o por defecto"
        fi
    else
        echo "   ❌ No tiene NEXT_PUBLIC_CONTRATO_ADDRESS"
    fi
else
    echo "   ❌ Archivo .env.local NO existe"
fi

echo ""
echo "2. Verificando contract-config.ts:"
if grep -q "0x0000000000000000000000000000000000000000" src/lib/contract-config.ts; then
    echo "   ❌ Usando dirección por defecto (no desplegado)"
else
    echo "   ✅ Dirección configurada o usando variable de entorno"
fi

echo ""
echo "3. Resumen:"
if [ -f .env.local ] && grep -q "NEXT_PUBLIC_CONTRATO_ADDRESS" .env.local; then
    ADDR=$(grep "NEXT_PUBLIC_CONTRATO_ADDRESS" .env.local | cut -d'=' -f2 | tr -d ' ')
    if [ "$ADDR" != "" ] && [ "$ADDR" != "0x0000000000000000000000000000000000000000" ]; then
        echo "   ✅ CONTRATOS CONFIGURADOS"
        echo "   📍 Dirección: $ADDR"
        echo ""
        echo "   Próximo paso: Verificar en el explorador que el contrato existe"
    else
        echo "   ❌ CONTRATOS NO CONFIGURADOS"
        echo "   Próximo paso: Desplegar contratos (ver DEPLOY_ARBITRUM_SEPOLIA.md)"
    fi
else
    echo "   ❌ CONTRATOS NO DESPLEGADOS"
    echo "   Próximo paso: Desplegar contratos (ver DEPLOY_ARBITRUM_SEPOLIA.md)"
fi
