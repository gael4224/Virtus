# 🚀 Desplegar Contrato en Arbitrum Sepolia

## Objetivo
Desplegar el contrato `GruposAhorroERC7913` en **Arbitrum Sepolia** para poder crear grupos desde el frontend.

## Prerrequisitos

### 1. Configurar MetaMask con Arbitrum Sepolia

**Agregar Red:**
- **Nombre de Red:** Arbitrum Sepolia
- **URL de RPC:** https://sepolia-rollup.arbitrum.io/rpc
- **ID de Cadena:** 421614 (0x66EEE)
- **Moneda:** ETH
- **Explorador de Bloques:** https://sepolia-explorer.arbitrum.io

### 2. Obtener ETH de Testnet

Necesitas ETH en Arbitrum Sepolia para pagar gas. Obtener de:
- **Faucet oficial de Arbitrum:** https://faucet.quicknode.com/arbitrum/sepolia
- **Faucet de Alchemy:** https://sepoliafaucet.com/
- **Faucet de Chainlink:** https://faucets.chain.link/arbitrum-sepolia

### 3. Para Pruebas Simples: Usar Contratos Mock

Para pruebas en testnet, puedes usar los **contratos mock** en lugar de los contratos reales de Aave:

1. Desplegar `TodosLosMocks.sol` en Arbitrum Sepolia
2. Usar esas direcciones para el contrato principal

---

## Opción A: Desplegar desde Remix IDE

### Paso 1: Preparar Remix

1. Abrir https://remix.ethereum.org/
2. Crear archivo `contracts/TodosLosMocks.sol`
   - Copiar contenido de `contracts/mocks/TodosLosMocks.sol`
3. Crear archivo `contracts/GruposAhorroERC7913.sol`
   - Copiar contenido de `contracts/erc7913/GruposAhorroERC7913.sol`
   - Si hay errores de import, copiar también `contracts/interfaces/IAaveInterfaces.sol`

### Paso 2: Compilar

1. **Compilar TodosLosMocks.sol:**
   - Versión: 0.8.20
   - Compilar los 3 contratos: MockWETH, MockAToken, MockAavePool

2. **Compilar GruposAhorroERC7913.sol:**
   - Versión: 0.8.24
   - Si hay errores de OpenZeppelin, usar versión simplificada

### Paso 3: Conectar MetaMask a Arbitrum Sepolia

1. En Remix, ir a "Deploy & Run Transactions"
2. Seleccionar "Injected Provider - MetaMask"
3. En MetaMask, cambiar a "Arbitrum Sepolia"
4. Verificar que tienes ETH en Arbitrum Sepolia

### Paso 4: Desplegar Contratos Mock

1. **Desplegar MockWETH:**
   - Contrato: `MockWETH`
   - Deploy → Copiar dirección

2. **Desplegar MockAToken:**
   - Contrato: `MockAToken`
   - Deploy → Copiar dirección

3. **Desplegar MockAavePool:**
   - Contrato: `MockAavePool`
   - Constructor:
     - `_weth`: Dirección de MockWETH
     - `_aWETH`: Dirección de MockAToken
   - Deploy → **IMPORTANTE:** Llamar `inicializar()` después del deploy
   - Copiar dirección

### Paso 5: Desplegar Contrato Principal

**Desplegar GruposAhorroERC7913:**
- Contrato: `GruposAhorroERC7913`
- Constructor:
  - `_aavePool`: Dirección de MockAavePool (paso 4.3)
  - `_weth`: Dirección de MockWETH (paso 4.1)
  - `_aWETH`: Dirección de MockAToken (paso 4.2)
  - `_usarAave`: `true`
  - `_cuentaFactory`: `0x0000000000000000000000000000000000000000`
- Deploy → **Copiar dirección** (esta es la importante)

---

## Opción B: Desplegar desde Hardhat

### Configurar Hardhat

1. **Instalar dependencias:**
```bash
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
```

2. **Crear hardhat.config.js:**
```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    arbitrumSepolia: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 421614
    }
  }
};
```

3. **Desplegar:**
```bash
npx hardhat run scripts/deploy.js --network arbitrumSepolia
```

---

## Actualizar Frontend

### 1. Actualizar contract-config.ts

Editar `snmontery/snmontery/src/lib/contract-config.ts`:

```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  '0x...TU_DIRECCION_DEL_CONTRATO...' as `0x${string}`;
```

### 2. Crear .env.local

Crear archivo `snmontery/snmontery/.env.local`:

```env
NEXT_PUBLIC_PRIVY_APP_ID=tu_app_id_de_privy
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...TU_DIRECCION_DEL_CONTRATO...
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

### 3. Reiniciar Servidor

```bash
cd snmontery/snmontery
npm run dev
```

---

## Crear Grupo de Prueba

### Desde el Frontend:

1. **Acceder al sistema:**
   - http://localhost:3001
   - Iniciar sesión con Privy
   - Asegurarse de estar en **Arbitrum Sepolia** en MetaMask

2. **Crear grupo:**
   - Ir a "Crear un Grupo"
   - **Nombre:** "Prueba 0.02 ETH"
   - **Objetivo:** `0.02` ETH
   - **Fecha Objetivo:** 31 de diciembre de 2025 (o cualquier fecha futura)
   - **Participantes:** 
     ```
     0x...direccion_segunda_persona...
     ```
     - Agregar la dirección de la segunda persona separada por coma

3. **Confirmar transacción:**
   - MetaMask pedirá confirmar
   - Asegurarse de estar en Arbitrum Sepolia
   - Confirmar y esperar

4. **Aportar fondos:**
   - En el dashboard, encontrar el grupo creado
   - Clic en "Aportar Fondos"
   - Cantidad: `0.01` ETH
   - Confirmar transacción

5. **Segunda persona aporta:**
   - La segunda persona debe conectarse
   - Ir al mismo grupo
   - Aportar `0.01` ETH
   - ✅ Meta alcanzada: `0.02 ETH`

---

## Direcciones a Guardar

Después del despliegue, guarda estas direcciones:

```
MockWETH: 0x...
MockAToken: 0x...
MockAavePool: 0x... (después de inicializar())
GruposAhorroERC7913: 0x... ← ESTA ES LA MÁS IMPORTANTE
```

---

## Verificación

1. ✅ Contratos desplegados en Arbitrum Sepolia
2. ✅ Direcciones guardadas
3. ✅ Frontend configurado con la dirección del contrato
4. ✅ MetaMask conectado a Arbitrum Sepolia
5. ✅ Tienes ETH en Arbitrum Sepolia

---

## Solución de Problemas

### Error: "Network not supported"
- Verifica que MetaMask esté en Arbitrum Sepolia
- Verifica que la red esté configurada correctamente

### Error: "Insufficient funds"
- Necesitas más ETH de testnet
- Obtén de los faucets mencionados

### Error: "Contract not found"
- Verifica que la dirección del contrato esté correcta
- Verifica que el contrato esté desplegado en Arbitrum Sepolia
- Usa el explorador de bloques: https://sepolia-explorer.arbitrum.io

---

**¡Listo para probar!** 🚀

