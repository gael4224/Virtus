# 🚀 Pasos para Desplegar SIN ERC-7913 (Versión Simple)

## ✅ Archivo a Usar

**Contrato:** `contracts/legacy/GruposAhorroConAaveMultisig.sol`

---

## 📝 Paso 1: Copiar Contrato a Remix

### En Remix:

1. **Crear archivo:** `contracts/GruposAhorroConAaveMultisig.sol`

2. **Copiar contenido:**
   - Abrir: `/home/gael-gonzalez/Documentos/HACKMTY/contracts/legacy/GruposAhorroConAaveMultisig.sol`
   - Copiar **TODO el contenido** (647 líneas)
   - Pegar en Remix
   - Guardar (Ctrl+S)

3. **✅ Verificar:** El archivo tiene interfaces incluidas al inicio (no necesita imports)

---

## 🔨 Paso 2: Compilar

1. **Ir a "Solidity Compiler"**
2. **Versión:** `0.8.20`
3. **Clic en:** "Compile GruposAhorroConAaveMultisig.sol"
4. **✅ Debe compilar sin errores**

---

## 📦 Paso 3: Desplegar Mocks Primero

Necesitas los mocks para que funcione:

### 3.1 Crear TodosLosMocks.sol

1. **Crear archivo:** `contracts/TodosLosMocks.sol`
2. **Copiar contenido de:**
   - `/home/gael-gonzalez/Documentos/HACKMTY/contracts/mocks/TodosLosMocks.sol`
3. **Compilar** con versión `0.8.20`

### 3.2 Desplegar Mocks

Ir a "Deploy & Run Transactions":

1. **MockWETH:**
   - Contrato: `MockWETH`
   - Constructor: Sin parámetros
   - Desplegar
   - ✅ Guardar dirección: `_________________`

2. **MockAToken:**
   - Contrato: `MockAToken`
   - Constructor: Sin parámetros
   - Desplegar
   - ✅ Guardar dirección: `_________________`

3. **MockAavePool:**
   - Contrato: `MockAavePool`
   - Constructor:
     - `_weth`: Dirección de MockWETH
     - `_aWETH`: Dirección de MockAToken
   - Desplegar
   - ✅ **CRÍTICO:** Llamar `inicializar()` después del deploy
   - ✅ Guardar dirección: `_________________`

---

## 🚀 Paso 4: Desplegar Contrato Principal

### En "Deploy & Run Transactions":

1. **Contrato:** `GruposAhorroConAaveMultisig`

2. **Constructor:**
   - `_aavePool`: Dirección de MockAavePool
   - `_weth`: Dirección de MockWETH
   - `_aWETH`: Dirección de MockAToken
   - `_usarAave`: `true` (sin comillas)

3. **Desplegar**

4. **✅ Guardar dirección:** `_________________` ← **IMPORTANTE**

---

## ✅ Paso 5: Configurar Frontend

### Actualizar `src/lib/contract-config.ts`:

```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  '0x...TU_DIRECCION_DEL_PASO_4...' as `0x${string}`;
```

O crear `.env.local`:

```env
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...TU_DIRECCION_DEL_PASO_4...
```

---

## 🎯 Funcionalidades Disponibles

Este contrato tiene:

- ✅ `crearGrupo()` - Crear grupos con multisig
- ✅ `aportar()` - Aportar fondos (deposita en Aave)
- ✅ `solicitarRetiro()` - Solicitar retiro de fondos
- ✅ `aprobarRetiro()` - Aprobar retiros (multisig)
- ✅ `ejecutarRetiro()` - Ejecutar retiro cuando se alcanza quorum
- ✅ `obtenerBalanceTotal()` - Ver balance con intereses
- ✅ `obtenerGrupo()` - Ver información del grupo
- ✅ Todo lo necesario para tu prueba con 0.02 ETH

---

## ⚠️ Notas Importantes

1. **Versión de Solidity:** `0.8.20` (no `0.8.24`)
2. **No requiere OpenZeppelin:** Compila directo en Remix
3. **Interfaces incluidas:** No necesitas archivo separado
4. **Multisig tradicional:** Funciona igual para tu caso de uso

---

## 🎉 ¡Listo!

Con esto ya puedes:
- ✅ Crear grupos desde el frontend
- ✅ Aportar fondos
- ✅ Ver intereses generados
- ✅ Retirar con aprobaciones multisig

**¡Perfecto para tu prueba de 0.02 ETH!** 🚀

