# ⚡ Guía Rápida: Probar Grupo de 0.02 ETH

## ✅ SÍ, ES POSIBLE

Puedes crear un grupo con:
- **Meta:** 0.02 ETH
- **Persona 1 aporta:** 0.01 ETH
- **Persona 2 aporta:** 0.01 ETH
- **Resultado:** Meta alcanzada ✅

---

## 📋 Checklist Rápido

### Antes de Empezar:

- [ ] Contrato desplegado en Arbitrum Sepolia
- [ ] Dirección del contrato guardada
- [ ] Frontend configurado con la dirección
- [ ] MetaMask conectado a Arbitrum Sepolia
- [ ] Tienes ETH en Arbitrum Sepolia (para gas)
- [ ] Segunda persona tiene wallet y dirección

---

## 🚀 Pasos Rápidos

### Paso 1: Desplegar Contrato

#### Usar Remix IDE:

1. **Abrir Remix:** https://remix.ethereum.org/

2. **Configurar Network:**
   - En "Deploy & Run Transactions"
   - Seleccionar "Injected Provider - MetaMask"
   - En MetaMask, cambiar a "Arbitrum Sepolia"

3. **Obtener ETH de Testnet:**
   - Ve a: https://faucet.quicknode.com/arbitrum/sepolia
   - Conecta tu wallet y solicita ETH

4. **Desplegar Mocks (Para Pruebas):**
   - Copiar `contracts/mocks/TodosLosMocks.sol` a Remix
   - Compilar (versión 0.8.20)
   - Desplegar en orden:
     - **MockWETH** → Copiar dirección
     - **MockAToken** → Copiar dirección
     - **MockAavePool** (con direcciones anteriores) → **LLAMAR `inicializar()`** → Copiar dirección

5. **Desplegar Contrato Principal:**
   - Copiar `contracts/erc7913/GruposAhorroERC7913.sol` a Remix
   - Compilar (versión 0.8.24)
   - Desplegar con:
     ```
     _aavePool: 0x...direccion_MockAavePool
     _weth: 0x...direccion_MockWETH
     _aWETH: 0x...direccion_MockAToken
     _usarAave: true
     _cuentaFactory: 0x0000000000000000000000000000000000000000
     ```
   - **GUARDAR DIRECCIÓN** ← Esta es la importante

---

### Paso 2: Configurar Frontend

1. **Editar `src/lib/contract-config.ts`:**
   ```typescript
   export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
     '0x...TU_DIRECCION_AQUI...' as `0x${string}`;
   ```

2. **Crear `.env.local` en `snmontery/snmontery/`:**
   ```env
   NEXT_PUBLIC_CONTRATO_ADDRESS=0x...TU_DIRECCION_AQUI...
   ```

3. **Reiniciar servidor:**
   ```bash
   npm run dev
   ```

---

### Paso 3: Crear Grupo

1. **Acceder:** http://localhost:3001
2. **Login:** Iniciar sesión con Privy
3. **Network:** Asegurarse de estar en **Arbitrum Sepolia** en MetaMask
4. **Crear Grupo:**
   - Ir a "Crear un Grupo"
   - **Nombre:** "Prueba 0.02 ETH"
   - **Objetivo:** `0.02` (ETH)
   - **Fecha:** Selecciona fecha futura (ej: 2025-12-31)
   - **Participantes:** `0x...direccion_persona_2...` (solo la dirección de la persona 2)
   - **Propósito:** Selecciona cualquier opción
5. **Confirmar:** Clic en "Crear Grupo" → Confirmar en MetaMask

---

### Paso 4: Aportar 0.01 ETH (Persona 1)

1. **En el dashboard, encontrar el grupo**
2. **Clic en "Aportar Fondos"**
3. **Cantidad:** `0.01` ETH
4. **Confirmar:** MetaMask pedirá confirmar
5. **Verificar:** Deberías ver "Total Recaudado: 0.01 ETH"

---

### Paso 5: Aportar 0.01 ETH (Persona 2)

1. **Persona 2 se conecta** (otra cuenta o wallet)
2. **Encuentra el grupo** (debería aparecer si fue agregado como participante)
3. **Aporta 0.01 ETH**
4. **Verificar:** Meta alcanzada ✅

---

## ✅ Verificación Final

Después de ambos aportes:

- ✅ Total Recaudado: **0.02 ETH**
- ✅ Balance Total: **0.02 ETH** (o más con intereses)
- ✅ Estado: **"Meta Alcanzada ✓"**
- ✅ Persona 1: **0.01 ETH** aportado
- ✅ Persona 2: **0.01 ETH** aportado
- ✅ Progreso: **100% completado**

---

## 🎯 Datos Exactos para tu Prueba

### Crear Grupo:
```
Nombre: "Prueba 0.02 ETH"
Objetivo: 0.02 (ETH)
Fecha: 2025-12-31 (o cualquier fecha futura)
Participantes: [tu_direccion, direccion_persona_2]
```

### Aportes:
```
Persona 1: 0.01 ETH
Persona 2: 0.01 ETH
Total: 0.02 ETH ✅
```

---

**¡Listo para probar!** 🚀

Para más detalles, ver:
- `DEPLOY_ARBITRUM_SEPOLIA.md` - Guía completa de despliegue
- `PASOS_PRUEBA_0.02_ETH.md` - Pasos detallados de prueba

