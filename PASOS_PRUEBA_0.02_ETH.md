# ✅ Pasos para Probar: Grupo de 0.02 ETH

## Objetivo
Crear un grupo con meta de **0.02 ETH** y que 2 personas aporten **0.01 ETH** cada una.

## ✅ SÍ ES POSIBLE

El sistema está diseñado para esto exactamente:
- Meta: 0.02 ETH
- Persona 1 aporta: 0.01 ETH
- Persona 2 aporta: 0.01 ETH
- ✅ Meta alcanzada: 0.02 ETH

---

## Pasos Completos

### 1️⃣ DESPLEGAR CONTRATOS (Una sola vez)

#### A. Usar Remix IDE (Más Fácil)

1. **Abrir Remix:** https://remix.ethereum.org/

2. **Conectar a Arbitrum Sepolia:**
   - En "Deploy & Run Transactions"
   - Seleccionar "Injected Provider - MetaMask"
   - En MetaMask, cambiar a "Arbitrum Sepolia"

3. **Obtener ETH de Testnet:**
   - Ve a: https://faucet.quicknode.com/arbitrum/sepolia
   - Conecta tu wallet y solicita ETH

4. **Desplegar Contratos Mock:**
   - Copiar `contracts/mocks/TodosLosMocks.sol` a Remix
   - Compilar (versión 0.8.20)
   - Desplegar:
     - **MockWETH** → Guardar dirección
     - **MockAToken** → Guardar dirección
     - **MockAavePool** (con direcciones anteriores) → **LLAMAR `inicializar()`** → Guardar dirección

5. **Desplegar Contrato Principal:**
   - Copiar `contracts/erc7913/GruposAhorroERC7913.sol` a Remix
   - Compilar (versión 0.8.24)
   - Desplegar con:
     - `_aavePool`: Dirección MockAavePool
     - `_weth`: Dirección MockWETH
     - `_aWETH`: Dirección MockAToken
     - `_usarAave`: `true`
     - `_cuentaFactory`: `0x0000000000000000000000000000000000000000`
   - **GUARDAR ESTA DIRECCIÓN** ← Importante

---

### 2️⃣ CONFIGURAR FRONTEND

1. **Editar `src/lib/contract-config.ts`:**
```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  '0x...TU_DIRECCION_AQUI...' as `0x${string}`;
```

2. **Crear `.env.local` en `snmontery/snmontery/`:**
```env
NEXT_PUBLIC_PRIVY_APP_ID=tu_app_id_de_privy
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...TU_DIRECCION_AQUI...
```

3. **Reiniciar servidor:**
```bash
cd snmontery/snmontery
npm run dev
```

---

### 3️⃣ CREAR GRUPO

1. **Acceder al sistema:**
   - http://localhost:3001
   - Iniciar sesión con Privy
   - Asegurarse de estar en **Arbitrum Sepolia** en MetaMask

2. **Obtener direcciones de participantes:**
   - **Persona 1 (Tú):** Tu dirección aparece en el dashboard (ej: `0xABC...`)
   - **Persona 2:** Obtener dirección de la segunda persona
     - Puede ser otra cuenta de Privy
     - O una dirección de MetaMask diferente

3. **Crear el grupo:**
   - Ir a "Crear un Grupo" o `/choose-saving/crear-grupo`
   - **Nombre:** "Prueba 0.02 ETH"
   - **Objetivo:** `0.02` (en ETH)
   - **Fecha Objetivo:** Selecciona una fecha futura (ej: 31 de diciembre de 2025)
   - **Participantes (Direcciones):** 
     ```
     0x...direccion_persona_2...
     ```
     - Solo agrega la dirección de la persona 2
     - Tu dirección se agrega automáticamente como creador
   - **Propósito:** Selecciona cualquier opción

4. **Confirmar:**
   - Clic en "Crear Grupo"
   - MetaMask pedirá confirmar
   - Verificar que estás en **Arbitrum Sepolia**
   - Confirmar transacción
   - Esperar confirmación (~30 segundos)

5. **Verificar:**
   - Serás redirigido al dashboard
   - Deberías ver el nuevo grupo en "Mis Grupos"

---

### 4️⃣ APORTAR FONDOS

#### Persona 1 (Tú):

1. **En el dashboard, encontrar el grupo creado**

2. **Clic en "Aportar Fondos"**

3. **Ingresar cantidad:**
   - Cantidad: `0.01` ETH
   - Clic en "Aportar" o "Confirmar"

4. **Confirmar transacción:**
   - MetaMask pedirá confirmar
   - Verificar cantidad: 0.01 ETH
   - Confirmar
   - Esperar confirmación

5. **Verificar:**
   - El grupo debería mostrar:
     - Total Recaudado: `0.01 ETH`
     - Tu Aporte: `0.01 ETH`
     - Balance Total: `0.01 ETH` (o ligeramente más si hay intereses)

---

#### Persona 2:

1. **Conectar su wallet:**
   - Iniciar sesión en el sistema con su cuenta
   - O conectar MetaMask con su dirección
   - Asegurarse de estar en **Arbitrum Sepolia**

2. **Obtener acceso al grupo:**
   - **Opción A:** Si fue agregado como participante, el grupo aparecerá en su dashboard
   - **Opción B:** Necesitará la dirección del grupo o el código de acceso
   - **Opción C:** Puedes compartir la dirección de la cuenta multisig del grupo

3. **Aportar 0.01 ETH:**
   - Encontrar el grupo
   - Clic en "Aportar Fondos"
   - Cantidad: `0.01` ETH
   - Confirmar transacción

4. **Verificar meta alcanzada:**
   - Después de la confirmación, el grupo debería mostrar:
     - Total Recaudado: `0.02 ETH` ✅
     - Balance Total: `0.02 ETH` (o más con intereses)
     - Estado: **"Meta Alcanzada ✓"** ✅
     - Progreso: **100% completado** ✅

---

## Verificación Final

Después de ambos aportes, deberías ver:

✅ **Objetivo:** 0.02 ETH  
✅ **Total Recaudado:** 0.02 ETH  
✅ **Balance Total:** 0.02 ETH (o ligeramente más con intereses)  
✅ **Persona 1 Aporte:** 0.01 ETH  
✅ **Persona 2 Aporte:** 0.01 ETH  
✅ **Estado:** "Meta Alcanzada ✓"  
✅ **Progreso:** 100% completado  

---

## Notas Importantes

1. **Network:** Debes estar conectado a **Arbitrum Sepolia** (Chain ID: 421614)

2. **Gas:** Necesitas ETH en Arbitrum Sepolia para pagar gas (las transacciones cuestan ~0.0001-0.001 ETH)

3. **Tiempo:** Las transacciones en Arbitrum Sepolia tardan ~1-2 segundos en confirmarse

4. **Intereses:** Si el contrato está usando Aave (mock), podrías ver pequeños intereses generados después de algunos bloques

---

## Solución Rápida de Problemas

### Error: "Network not supported"
→ Cambia MetaMask a Arbitrum Sepolia

### Error: "Insufficient funds"
→ Necesitas más ETH de testnet (obtener de faucet)

### Error: "Contract not found"
→ Verifica que la dirección del contrato esté correcta en `contract-config.ts`

### No aparece el grupo
→ Verifica que la transacción fue exitosa en el explorador:
https://sepolia-explorer.arbitrum.io

---

## Resumen

**SÍ, es totalmente posible:**
- ✅ Crear grupo con meta de 0.02 ETH
- ✅ Persona 1 aporta 0.01 ETH
- ✅ Persona 2 aporta 0.01 ETH
- ✅ Meta alcanzada: 0.02 ETH total

**Pasos clave:**
1. Desplegar contratos en Arbitrum Sepolia
2. Configurar dirección del contrato en frontend
3. Crear grupo desde el frontend
4. Aportar 0.01 ETH cada persona
5. ✅ ¡Meta alcanzada!

---

**¡Listo para probar!** 🚀

