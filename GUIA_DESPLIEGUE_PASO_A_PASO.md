# 🚀 Guía Paso a Paso: Desplegar Contrato en Remix

## 📋 Checklist Pre-Despliegue

Antes de empezar, verifica que tienes:

- [ ] MetaMask instalado y configurado
- [ ] Arbitrum Sepolia agregado en MetaMask (Chain ID: 421614)
- [ ] ETH de testnet en Arbitrum Sepolia (para gas)
- [ ] Remix IDE abierto (https://remix.ethereum.org/)

---

## 🔧 Paso 1: Preparar Remix

### 1.1 Abrir Remix
1. Ve a: **https://remix.ethereum.org/**
2. Si es tu primera vez, Remix se inicializará automáticamente

### 1.2 Conectar MetaMask
1. Ir a la pestaña **"Deploy & Run Transactions"** (icono de caja en el panel izquierdo)
2. En **"Environment"**, seleccionar: **"Injected Provider - MetaMask"**
3. **IMPORTANTE:** En MetaMask, cambiar a la red **"Arbitrum Sepolia"**
   - Si no aparece, agregarla manualmente:
     - **Network Name:** Arbitrum Sepolia
     - **RPC URL:** https://sepolia-rollup.arbitrum.io/rpc
     - **Chain ID:** 421614
     - **Currency Symbol:** ETH
     - **Block Explorer:** https://sepolia-explorer.arbitrum.io

### 1.3 Verificar ETH de Testnet
1. Verificar en MetaMask que tienes ETH en Arbitrum Sepolia
2. Si no tienes, obtener de un faucet:
   - **Faucet 1:** https://faucet.quicknode.com/arbitrum/sepolia
   - **Faucet 2:** https://sepoliafaucet.com/
   - Conectar wallet y solicitar ETH

---

## 📝 Paso 2: Copiar Contratos a Remix

### 2.1 Crear Estructura de Carpetas

En Remix, en el panel izquierdo **"File Explorer"**:

1. Si no existe, Remix crea automáticamente la carpeta `contracts`
2. **No necesitas crear subcarpetas** - todo va en `contracts/`

### 2.2 Copiar `TodosLosMocks.sol`

1. **Crear archivo en Remix:**
   - Clic derecho en `contracts` → **"New File"**
   - Nombre: `TodosLosMocks.sol`
   - Presionar Enter

2. **Abrir archivo local:**
   - Ruta: `/home/gael-gonzalez/Documentos/HACKMTY/contracts/mocks/TodosLosMocks.sol`

3. **Copiar TODO el contenido:**
   - Seleccionar todo (Ctrl+A o Cmd+A)
   - Copiar (Ctrl+C o Cmd+C)

4. **Pegar en Remix:**
   - Abrir `contracts/TodosLosMocks.sol` en Remix
   - Pegar el contenido (Ctrl+V o Cmd+V)
   - **Guardar** (Ctrl+S o Cmd+S)

✅ **Verificar:** El archivo debe tener ~122 líneas

---

### 2.3 Copiar `GruposAhorroConAaveMultisig.sol`

1. **Crear archivo en Remix:**
   - Clic derecho en `contracts` → **"New File"**
   - Nombre: `GruposAhorroConAaveMultisig.sol`
   - Presionar Enter

2. **Abrir archivo local:**
   - Ruta: `/home/gael-gonzalez/Documentos/HACKMTY/contracts/legacy/GruposAhorroConAaveMultisig.sol`

3. **Copiar TODO el contenido:**
   - Seleccionar todo (Ctrl+A)
   - Copiar (Ctrl+C)

4. **Pegar en Remix:**
   - Abrir `contracts/GruposAhorroConAaveMultisig.sol` en Remix
   - Pegar el contenido (Ctrl+V)
   - **Guardar** (Ctrl+S)

✅ **Verificar:** El archivo debe tener ~648 líneas

---

## 🔨 Paso 3: Compilar Contratos

### 3.1 Compilar `TodosLosMocks.sol`

1. Ir a la pestaña **"Solidity Compiler"** (icono de engranaje en el panel izquierdo)
2. **Versión del compilador:** Seleccionar **0.8.20**
3. En el dropdown de archivos, seleccionar: **"TodosLosMocks.sol"**
4. Clic en **"Compile TodosLosMocks.sol"**
5. ✅ **Verificar:** Debe aparecer ícono verde ✅ sin errores
6. ✅ **Verificar:** En "Deploy & Run Transactions", deben aparecer 3 contratos:
   - `MockWETH`
   - `MockAToken`
   - `MockAavePool`

---

### 3.2 Compilar `GruposAhorroConAaveMultisig.sol`

1. En **"Solidity Compiler"**
2. **Versión del compilador:** Seleccionar **0.8.20** (la misma)
3. En el dropdown de archivos, seleccionar: **"GruposAhorroConAaveMultisig.sol"**
4. Clic en **"Compile GruposAhorroConAaveMultisig.sol"**
5. ✅ **Verificar:** Debe aparecer ícono verde ✅ sin errores
6. ✅ **Verificar:** En "Deploy & Run Transactions", debe aparecer:
   - `GruposAhorroConAaveMultisig`

---

## 📦 Paso 4: Desplegar Contratos Mock

Ir a la pestaña **"Deploy & Run Transactions"**

### 4.1 Desplegar MockWETH

1. **Contrato:** Seleccionar `MockWETH` del dropdown
2. **Constructor:** Sin parámetros (dejar vacío)
3. **Account:** Seleccionar tu cuenta de MetaMask (debe tener ETH)
4. **Value:** 0 ETH
5. Clic en **"Deploy"**
6. **MetaMask:** Confirmar transacción
7. ✅ **Verificar:** `status: 0x1 Transaction mined and execution succeed`
8. ✅ **Copiar dirección:** Clic derecho en el contrato desplegado → **"Copy address"**
9. ✅ **Guardar dirección:** `_________________` ← Anotar esta dirección

---

### 4.2 Desplegar MockAToken

1. **Contrato:** Seleccionar `MockAToken` del dropdown
2. **Constructor:** Sin parámetros
3. Clic en **"Deploy"**
4. **MetaMask:** Confirmar transacción
5. ✅ **Verificar:** `status: 0x1 Transaction mined and execution succeed`
6. ✅ **Copiar dirección:** Clic derecho → **"Copy address"**
7. ✅ **Guardar dirección:** `_________________` ← Anotar esta dirección

---

### 4.3 Desplegar MockAavePool

1. **Contrato:** Seleccionar `MockAavePool` del dropdown
2. **Constructor:**
   - **Parámetro 1 (`_weth`):** Pegar dirección de `MockWETH` (paso 4.1)
   - **Parámetro 2 (`_aWETH`):** Pegar dirección de `MockAToken` (paso 4.2)
3. Clic en **"Deploy"**
4. **MetaMask:** Confirmar transacción
5. ✅ **Verificar:** `status: 0x1 Transaction mined and execution succeed`
6. ✅ **Copiar dirección:** Clic derecho → **"Copy address"**
7. ✅ **Guardar dirección:** `_________________` ← Anotar esta dirección

---

### 4.4 ⚠️ CRÍTICO: Inicializar MockAavePool

**IMPORTANTE:** Este paso es obligatorio. Sin él, obtendrás errores.

1. **Expandir** `MockAavePool` en "Deployed Contracts" (clic en la flecha ▶)
2. **Buscar función:** `inicializar` (sin parámetros)
3. **Clic en** `inicializar` (botón transact)
4. **MetaMask:** Confirmar transacción
5. ✅ **Verificar:** `status: 0x1 Transaction mined and execution succeed`

✅ **Si ves esto:** `status: 0x1` → MockAavePool está inicializado correctamente

---

## 🚀 Paso 5: Desplegar Contrato Principal

### 5.1 Desplegar `GruposAhorroConAaveMultisig`

1. **Contrato:** Seleccionar `GruposAhorroConAaveMultisig` del dropdown
2. **Constructor - Parámetros:**
   - **Parámetro 1 (`_aavePool`):** Dirección de `MockAavePool` (paso 4.3)
   - **Parámetro 2 (`_weth`):** Dirección de `MockWETH` (paso 4.1)
   - **Parámetro 3 (`_aWETH`):** Dirección de `MockAToken` (paso 4.2)
   - **Parámetro 4 (`_usarAave`):** `true` (sin comillas, solo la palabra `true`)
3. Clic en **"Deploy"**
4. **MetaMask:** Confirmar transacción
5. ✅ **Verificar:** `status: 0x1 Transaction mined and execution succeed`
6. ✅ **Copiar dirección:** Clic derecho → **"Copy address"**
7. ✅ **Guardar dirección:** `_________________` ← **ESTA ES LA MÁS IMPORTANTE**

---

## ✅ Paso 6: Verificar en el Explorador

1. **Abrir Explorador:**
   - https://sepolia-explorer.arbitrum.io

2. **Pegar dirección** del contrato principal (`GruposAhorroConAaveMultisig`)

3. ✅ **Verificar:**
   - Debe mostrar información del contrato
   - Debe mostrar transacciones (deploy, etc.)
   - Debe mostrar el código si fue verificado

✅ **Si aparece:** El contrato está desplegado correctamente

---

## 📝 Paso 7: Configurar Frontend

### 7.1 Crear `.env.local`

Crear archivo: `snmontery/snmontery/.env.local`

```env
NEXT_PUBLIC_PRIVY_APP_ID=tu_app_id_de_privy
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...TU_DIRECCION_DEL_PASO_5...
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

**Reemplazar:**
- `0x...TU_DIRECCION_DEL_PASO_5...` con la dirección del contrato principal desplegado

---

### 7.2 Reiniciar Servidor Frontend

```bash
cd snmontery/snmontery
npm run dev
```

---

## 🎯 Paso 8: Verificar Funcionamiento

### 8.1 Crear Grupo desde Frontend

1. Abrir: http://localhost:3001
2. Iniciar sesión con Privy
3. Cambiar a Arbitrum Sepolia en MetaMask
4. Ir a "Crear Grupo"
5. Llenar formulario:
   - **Nombre:** "Grupo de Prueba"
   - **Objetivo:** 0.02 ETH
   - **Fecha:** Fecha futura
   - **Descripción:** "Prueba del sistema"
   - **Participantes:** Agregar otra dirección (opcional)
6. Clic en "Crear Grupo"
7. **MetaMask:** Confirmar transacción
8. ✅ **Verificar:** Grupo creado exitosamente

---

### 8.2 Aportar Fondos

1. En el dashboard, ver tu grupo creado
2. Clic en **"Aportar Fondos"**
3. Ingresar cantidad: **0.01 ETH**
4. Clic en **"Aportar Fondos"**
5. **MetaMask:** Confirmar transacción
6. ✅ **Verificar:** Balance actualizado

---

## 📋 Resumen de Direcciones

Después del despliegue, guarda estas direcciones:

```
MockWETH: 0x...
MockAToken: 0x...
MockAavePool: 0x... (después de inicializar)
GruposAhorroConAaveMultisig: 0x... ← ESTA ES LA MÁS IMPORTANTE
```

**Para el frontend, solo necesitas la dirección de `GruposAhorroConAaveMultisig`.**

---

## ⚠️ Errores Comunes y Soluciones

### Error: "Insufficient funds"
**Causa:** No tienes suficiente ETH en Arbitrum Sepolia  
**Solución:** Obtener más ETH del faucet

### Error: "Only pool can mint" al aportar
**Causa:** No llamaste `inicializar()` en MockAavePool  
**Solución:** Ir a paso 4.4 y llamar `inicializar()`

### Error: "Contract not found" en frontend
**Causa:** Dirección incorrecta en `.env.local`  
**Solución:** Verificar que la dirección sea correcta y reiniciar servidor

### Error: "Invalid contract address"
**Causa:** Dirección no es un contrato válido  
**Solución:** Verificar en el explorador que el contrato existe

---

## ✅ Checklist Final

- [ ] Todos los contratos compilados sin errores
- [ ] MockWETH desplegado → Dirección guardada
- [ ] MockAToken desplegado → Dirección guardada
- [ ] MockAavePool desplegado → Dirección guardada
- [ ] **MockAavePool.inicializar() llamado** ✅
- [ ] GruposAhorroConAaveMultisig desplegado → Dirección guardada
- [ ] Contrato verificado en explorador
- [ ] `.env.local` creado con dirección
- [ ] Frontend reiniciado
- [ ] Grupo creado desde frontend
- [ ] Aportes realizados exitosamente

---

**¡Listo para desplegar!** 🚀

Si tienes algún problema durante el despliegue, avísame y te ayudo a resolverlo.

