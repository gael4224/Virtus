# ⚙️ Configuración del Frontend

## ✅ Contrato Desplegado

**Dirección del Contrato Principal:**
```
0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec
```

---

## 📝 Configuración del Frontend

### Opción 1: Usar Variable de Entorno (Recomendado)

Crear archivo: `snmontery/snmontery/.env.local`

```env
NEXT_PUBLIC_CONTRATO_ADDRESS=0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

### Opción 2: Ya está Hardcodeado

El archivo `src/lib/contract-config.ts` ya tiene la dirección actualizada:
```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  process.env.NEXT_PUBLIC_CONTRATO_ADDRESS || 
  '0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec' as `0x${string}`;
```

---

## 🚀 Reiniciar Servidor

```bash
cd snmontery/snmontery
npm run dev
```

---

## ✅ Verificar que Funciona

1. Abrir: http://localhost:3001
2. Iniciar sesión con Privy
3. Cambiar a Arbitrum Sepolia en MetaMask
4. Ir a "Crear Grupo"
5. Crear un grupo de prueba
6. ✅ Debe funcionar correctamente

---

**¡El sistema está listo para usar!** 🚀

