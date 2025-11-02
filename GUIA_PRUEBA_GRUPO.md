# 🧪 Guía para Probar Creación de Grupo

## Objetivo
Crear un grupo con meta de **0.02 ETH** y dos personas aportando **0.01 ETH** cada una en **Arbitrum Sepolia**.

## Prerrequisitos

### 1. Contrato Desplegado
- ✅ El contrato `GruposAhorroERC7913` debe estar desplegado en Arbitrum Sepolia
- ✅ Los contratos mock (MockWETH, MockAToken, MockAavePool) deben estar desplegados O usar contratos reales de Aave

### 2. Variables de Entorno
Crear archivo `.env.local` en `snmontery/snmontery/`:
```env
NEXT_PUBLIC_PRIVY_APP_ID=tu_app_id_de_privy
NEXT_PUBLIC_CONTRATO_ADDRESS=0x... # Dirección del contrato GruposAhorroERC7913 desplegado
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

### 3. Configuración del Contrato
Actualizar `src/lib/contract-config.ts`:
```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = '0x...' as `0x${string}`; // Tu dirección del contrato
```

## Pasos para Crear el Grupo

### Paso 1: Preparar Direcciones de Participantes

Necesitas 2 direcciones de wallet:
- **Persona 1 (Creador):** Tu dirección de wallet conectada en Privy
- **Persona 2:** Dirección de la segunda persona

**Obtener tu dirección:**
1. Inicia sesión en el sistema
2. En el dashboard, verás tu dirección de wallet en el status
3. Copia esa dirección

**Nota:** Si la segunda persona no tiene wallet, puedes:
- Usar otra cuenta de Privy (segunda cuenta)
- O usar una dirección de MetaMask diferente

### Paso 2: Crear el Grupo

1. **Acceder al sistema:**
   - Abre http://localhost:3001
   - Inicia sesión con Privy

2. **Ir a "Crear Grupo":**
   - En el dashboard, haz clic en "Crear un Grupo"
   - O ve directamente a `/choose-saving/crear-grupo`

3. **Completar el formulario:**
   - **Nombre del Grupo:** "Prueba Ahorro 0.02 ETH"
   - **Objetivo:** `0.02` (en ETH)
   - **Fecha del Objetivo:** Selecciona una fecha futura (ej: 31 de diciembre de 2025)
   - **Participantes (Direcciones):** 
     ```
     0x...direccion_persona_2...
     ```
     - Separa direcciones con comas si hay más
     - Ejemplo: `0x123..., 0x456...`
   - **Propósito:** Selecciona "Otro" o cualquier opción

4. **Hacer clic en "Crear Grupo"**

5. **Confirmar transacción:**
   - Privy/MetaMask te pedirá confirmar la transacción
   - Asegúrate de estar en **Arbitrum Sepolia**
   - Confirma y espera la confirmación

6. **Verificar:**
   - Después de confirmar, serás redirigido al dashboard
   - Deberías ver el nuevo grupo en "Mis Grupos"

### Paso 3: Aportar Fondos (Persona 1)

1. **En el dashboard:**
   - Encuentra el grupo creado
   - Haz clic en "Aportar Fondos"

2. **Ingresar cantidad:**
   - Cantidad: `0.01` ETH
   - Confirma la transacción
   - Espera la confirmación

3. **Verificar:**
   - El balance del grupo debería mostrar `0.01 ETH` recaudado
   - Tu aporte personal debería mostrar `0.01 ETH`

### Paso 4: Aportar Fondos (Persona 2)

La segunda persona debe:

1. **Conectar su wallet:**
   - Iniciar sesión en el sistema con su cuenta
   - O conectar MetaMask con su dirección

2. **Acceder al grupo:**
   - Si el grupo aparece en su dashboard (si fue agregado como participante)
   - O usar el código/dirección del grupo para acceder

3. **Aportar 0.01 ETH:**
   - Hacer clic en "Aportar Fondos"
   - Ingresar: `0.01` ETH
   - Confirmar transacción

4. **Verificar meta alcanzada:**
   - El balance total debería mostrar `0.02 ETH`
   - El estado del grupo debería cambiar a "Meta Alcanzada ✓"

## Datos Exactos para la Prueba

### Crear Grupo:
- **Nombre:** "Prueba Ahorro 0.02 ETH"
- **Objetivo:** `0.02` ETH
- **Fecha Objetivo:** Cualquier fecha futura (ej: `2025-12-31`)
- **Participantes:** `[direccion_persona_1, direccion_persona_2]`
- **Descripción:** "Prueba de ahorro grupal"

### Aportes:
- **Persona 1:** `0.01` ETH
- **Persona 2:** `0.01` ETH
- **Total:** `0.02` ETH ✅

## Verificación

Después de ambos aportes, deberías ver:

1. **Balance Total:** `0.02 ETH` o ligeramente más (si hay intereses)
2. **Total Recaudado:** `0.02 ETH`
3. **Estado:** "Meta Alcanzada ✓"
4. **Aporte Persona 1:** `0.01 ETH`
5. **Aporte Persona 2:** `0.01 ETH`

## Notas Importantes

1. **Network:** Asegúrate de estar conectado a **Arbitrum Sepolia** en MetaMask
2. **Gas:** Necesitarás ETH en Arbitrum Sepolia para pagar gas
3. **Tiempo:** Las transacciones pueden tardar unos segundos en confirmarse
4. **Intereses:** Si el contrato está usando Aave, podrías ver pequeños intereses generados

## Solución de Problemas

### Error: "Contrato no encontrado"
- Verifica que `NEXT_PUBLIC_CONTRATO_ADDRESS` esté configurado correctamente
- Verifica que el contrato esté desplegado en Arbitrum Sepolia

### Error: "Network incorrecta"
- Asegúrate de estar en Arbitrum Sepolia en MetaMask
- Si usas Privy, verifica que la red esté configurada

### Error: "Insufficient funds"
- Necesitas ETH en Arbitrum Sepolia para pagar gas
- Puedes obtener ETH de testnet de faucets de Arbitrum Sepolia

## Siguiente Paso

Después de probar la creación y aportes, puedes:
- Verificar los intereses generados (si está usando Aave)
- Probar retirar fondos (requiere multisig cuando la meta está alcanzada)
- Crear más grupos con diferentes configuraciones

