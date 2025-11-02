# 🚀 Pasos para Desplegar en Arbitrum Sepolia desde Remix

## Paso 1: Preparar Remix

1. **Abrir Remix IDE:**
   - https://remix.ethereum.org/

2. **Conectar MetaMask:**
   - En la pestaña "Deploy & Run Transactions"
   - Seleccionar "Injected Provider - MetaMask"
   - **IMPORTANTE:** En MetaMask, cambiar a "Arbitrum Sepolia"
     - Si no aparece, agregar manualmente:
       - Network: Arbitrum Sepolia
       - Chain ID: 421614
       - RPC: https://sepolia-rollup.arbitrum.io/rpc

3. **Obtener ETH de Testnet:**
   - Ve a: https://faucet.quicknode.com/arbitrum/sepolia
   - Conecta tu wallet
   - Solicita ETH de testnet
   - Espera confirmación (~1 minuto)

---

## Paso 2: Copiar Contratos a Remix

### Archivo 1: TodosLosMocks.sol

1. **En Remix:**
   - Crear carpeta `contracts` (si no existe)
   - Crear archivo: `contracts/TodosLosMocks.sol`

2. **Copiar contenido:**
   - Abrir: `/home/gael-gonzalez/Documentos/HACKMTY/contracts/mocks/TodosLosMocks.sol`
   - Copiar TODO el contenido
   - Pegar en Remix
   - Guardar (Ctrl+S o Cmd+S)

### Archivo 2: GruposAhorroERC7913.sol

1. **En Remix:**
   - Crear archivo: `contracts/GruposAhorroERC7913.sol`

2. **Copiar contenido:**
   - Abrir: `/home/gael-gonzalez/Documentos/HACKMTY/contracts/erc7913/GruposAhorroERC7913.sol`
   - Copiar TODO el contenido
   - **IMPORTANTE:** Si tiene import `../../interfaces/IAaveInterfaces.sol`:
     - Crear también `contracts/interfaces/IAaveInterfaces.sol` en Remix
     - Copiar contenido de `/home/gael-gonzalez/Documentos/HACKMTY/contracts/interfaces/IAaveInterfaces.sol`

---

## Paso 3: Compilar

### 3.1 Compilar TodosLosMocks.sol

1. Ir a pestaña "Solidity Compiler"
2. Versión: **0.8.20**
3. Clic en "Compile TodosLosMocks.sol"
4. ✅ Verificar: Sin errores (ícono verde)

### 3.2 Compilar GruposAhorroERC7913.sol

1. Versión: **0.8.24**
2. Clic en "Compile GruposAhorroERC7913.sol"
3. ✅ Verificar: Sin errores
4. **Si hay errores de OpenZeppelin:**
   - Puede ser que Remix no tenga las dependencias
   - En ese caso, usar versión simplificada sin ERC-7913

---

## Paso 4: Desplegar Contratos Mock

**Ir a pestaña "Deploy & Run Transactions"**

### 4.1 Desplegar MockWETH

1. **Contrato:** `MockWETH` (del dropdown)
2. **Constructor:** Sin parámetros
3. **Clic en:** "Deploy"
4. **Verificar:** Aparece en "Deployed Contracts"
5. **Copiar dirección:** Ejemplo `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`
6. **Guardar:** Anotar esta dirección

**Dirección MockWETH:** `_________________`

---

### 4.2 Desplegar MockAToken

1. **Contrato:** `MockAToken` (del dropdown)
2. **Constructor:** Sin parámetros
3. **Clic en:** "Deploy"
4. **Verificar:** Aparece en "Deployed Contracts"
5. **Copiar dirección:** Ejemplo `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`
6. **Guardar:** Anotar esta dirección

**Dirección MockAToken:** `_________________`

---

### 4.3 Desplegar MockAavePool

1. **Contrato:** `MockAavePool` (del dropdown)
2. **Constructor:**
   - `_weth`: Dirección de MockWETH (paso 4.1)
   - `_aWETH`: Dirección de MockAToken (paso 4.2)
3. **Clic en:** "Deploy"
4. **Verificar:** Aparece en "Deployed Contracts"

**CRÍTICO - Llamar inicializar():**

1. **Expandir** `MockAavePool` en "Deployed Contracts"
2. **Buscar** función `inicializar`
3. **Clic en** `inicializar` (o `transact`)
4. **Verificar:** `status: 0x1 Transaction mined and execution succeed`
5. **Copiar dirección:** Ejemplo `0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692`
6. **Guardar:** Anotar esta dirección

**Dirección MockAavePool:** `_________________`

⚠️ **SI NO LLAMAS `inicializar()`, OBTENDRÁS ERROR "Only pool can mint"**

---

## Paso 5: Desplegar Contrato Principal

### 5.1 Desplegar GruposAhorroERC7913

1. **Contrato:** `GruposAhorroERC7913` (del dropdown)
2. **Constructor:**
   - `_aavePool`: Dirección de MockAavePool (paso 4.3)
   - `_weth`: Dirección de MockWETH (paso 4.1)
   - `_aWETH`: Dirección de MockAToken (paso 4.2)
   - `_usarAave`: `true` (sin comillas)
   - `_cuentaFactory`: `0x0000000000000000000000000000000000000000`
3. **Clic en:** "Deploy"
4. **Verificar:** Aparece en "Deployed Contracts"
5. **Copiar dirección:** **ESTA ES LA MÁS IMPORTANTE**
6. **Guardar:** Esta es la dirección que usarás en el frontend

**Dirección GruposAhorroERC7913:** `_________________` ← **IMPORTANTE**

---

## Paso 6: Verificar en el Explorador

1. **Abrir Explorador:**
   - https://sepolia-explorer.arbitrum.io

2. **Pegar dirección** del contrato principal (`GruposAhorroERC7913`)

3. **Verificar:**
   - ✅ Debe mostrar información del contrato
   - ✅ Debe mostrar transacciones (deploy, etc.)
   - ✅ Debe mostrar el código si fue verificado

**Si aparece:** ✅ Contrato desplegado correctamente  
**Si NO aparece:** ❌ Error en el despliegue

---

## Paso 7: Configurar Frontend

### 7.1 Crear .env.local

Crear archivo `snmontery/snmontery/.env.local`:

```env
NEXT_PUBLIC_PRIVY_APP_ID=tu_app_id_de_privy
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...TU_DIRECCION_DEL_PASO_5...
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

### 7.2 Actualizar contract-config.ts (Opcional)

Si prefieres hardcodear la dirección en lugar de usar .env.local:

Editar `src/lib/contract-config.ts`:

```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  '0x...TU_DIRECCION...' as `0x${string}`;
```

### 7.3 Reiniciar Servidor

```bash
cd snmontery/snmontery
npm run dev
```

---

## ✅ Verificación Final

Después de configurar, verifica:

1. ✅ Contratos desplegados en Arbitrum Sepolia
2. ✅ Direcciones guardadas
3. ✅ `.env.local` creado con `NEXT_PUBLIC_CONTRATO_ADDRESS`
4. ✅ Servidor reiniciado
5. ✅ Frontend puede crear grupos (probar creando uno)

---

## 📋 Checklist de Despliegue

- [ ] MetaMask conectado a Arbitrum Sepolia
- [ ] Tienes ETH en Arbitrum Sepolia (para gas)
- [ ] MockWETH desplegado → Dirección guardada
- [ ] MockAToken desplegado → Dirección guardada
- [ ] MockAavePool desplegado → Dirección guardada
- [ ] **MockAavePool.inicializar()** llamado ✅
- [ ] GruposAhorroERC7913 desplegado → Dirección guardada
- [ ] Contrato verificado en explorador
- [ ] `.env.local` creado con dirección
- [ ] Frontend reiniciado
- [ ] Puedes crear grupos desde el frontend

---

## 🎯 Direcciones a Guardar

Después del despliegue, guarda estas direcciones:

```
MockWETH: 0x...
MockAToken: 0x...
MockAavePool: 0x... (después de inicializar)
GruposAhorroERC7913: 0x... ← ESTA ES LA MÁS IMPORTANTE
```

**Para el frontend, solo necesitas la dirección de `GruposAhorroERC7913`.**

---

**¡Listo para desplegar!** 🚀

