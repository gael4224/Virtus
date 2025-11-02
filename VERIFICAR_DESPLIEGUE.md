# ✅ Cómo Verificar si los Contratos Están Desplegados

## 🔍 Formas de Verificar

### 1️⃣ Verificar Configuración en el Código

#### Archivo: `src/lib/contract-config.ts`

Abre el archivo y verifica:

```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  process.env.NEXT_PUBLIC_CONTRATO_ADDRESS || 
  '0x0000000000000000000000000000000000000000' as `0x${string}`;
```

**Si muestra:**
- ❌ `'0x0000000000000000000000000000000000000000'` → **NO está desplegado**
- ✅ `'0x1234567890abcdef...'` (dirección real) → **Está configurado**

#### Archivo: `.env.local` (en `snmontery/snmontery/`)

```env
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...
```

**Si no existe el archivo o está vacío:** ❌ NO está configurado

---

### 2️⃣ Verificar en el Explorador de Bloques

Si tienes la dirección del contrato, verifícala en:

**Explorador de Arbitrum Sepolia:**
- https://sepolia-explorer.arbitrum.io

**Pasos:**
1. Abre el explorador
2. Pega la dirección del contrato en la búsqueda
3. **Si existe:** Verás:
   - ✅ Información del contrato
   - ✅ Código fuente (si fue verificado)
   - ✅ Transacciones realizadas
   - ✅ Estado del contrato
4. **Si NO existe:** Verás error "Contract not found"

---

### 3️⃣ Verificar desde el Frontend

#### Opción A: Intentar Crear un Grupo

1. Abre http://localhost:3001
2. Inicia sesión con Privy
3. Asegúrate de estar en **Arbitrum Sepolia** en MetaMask
4. Intenta crear un grupo

**Si el contrato NO está desplegado:**
- ❌ Error: "Contract not found"
- ❌ Error: "Cannot read properties of undefined"
- ❌ Transacción falla

**Si el contrato SÍ está desplegado:**
- ✅ MetaMask pide confirmar transacción
- ✅ Transacción se envía exitosamente
- ✅ Recibes hash de transacción
- ✅ Grupo se crea correctamente

#### Opción B: Verificar en la Consola del Navegador

1. Abre las herramientas de desarrollador (F12)
2. Ve a la pestaña "Console"
3. Si hay errores relacionados con el contrato, verás:
   - `Contract address is 0x0000...` → No desplegado
   - `Cannot read contract` → No desplegado o dirección incorrecta

---

### 4️⃣ Verificar Variables de Entorno

Ejecuta en la terminal:

```bash
cd snmontery/snmontery
cat .env.local | grep CONTRATO
```

**Si muestra:**
- ❌ Nada o línea vacía → No configurado
- ✅ `NEXT_PUBLIC_CONTRATO_ADDRESS=0x...` → Configurado

---

## 🎯 Verificación Rápida

### Checklist:

- [ ] **Archivo `.env.local` existe** en `snmontery/snmontery/`
- [ ] **Variable `NEXT_PUBLIC_CONTRATO_ADDRESS`** tiene una dirección (no `0x0000...`)
- [ ] **Dirección es válida** (empieza con `0x` y tiene 42 caracteres)
- [ ] **Contrato existe en el explorador** (verificar en https://sepolia-explorer.arbitrum.io)
- [ ] **Frontend puede interactuar** (intentar crear grupo funciona)

---

## 🔧 Cómo Verificar Manualmente en Remix

Si desplegaste desde Remix:

1. **Abrir Remix:** https://remix.ethereum.org/
2. **Ir a "Deploy & Run Transactions"**
3. **Verificar "Deployed Contracts"**
4. **Buscar `GruposAhorroERC7913`**
5. **Copiar dirección** (ej: `0xAb8...35C`)

**Si aparece:** ✅ Contrato desplegado en Remix

**Importante:** Asegúrate de estar en la misma red (Arbitrum Sepolia) que el frontend.

---

## 📝 Qué Direcciones Necesitas

Para que todo funcione, necesitas:

1. **GruposAhorroERC7913** ← **PRINCIPAL** (esta es la más importante)
   - Dirección: `0x...`
   - Se usa para crear grupos

2. **MockAavePool** (opcional, si usas mocks)
3. **MockWETH** (opcional, si usas mocks)
4. **MockAToken** (opcional, si usas mocks)

**Para el frontend, solo necesitas la dirección de `GruposAhorroERC7913`.**

---

## 🚨 Si NO Están Desplegados

### Opción 1: Desplegar desde Remix (Recomendado)

1. **Abrir Remix:** https://remix.ethereum.org/
2. **Conectar a Arbitrum Sepolia**
3. **Desplegar contratos** (ver `DEPLOY_ARBITRUM_SEPOLIA.md`)
4. **Copiar dirección** del contrato principal
5. **Actualizar configuración** en frontend

### Opción 2: Usar Contratos Ya Desplegados

Si alguien ya desplegó los contratos:
1. **Obtener dirección** del contrato desplegado
2. **Verificar en el explorador** que existe
3. **Actualizar configuración** en frontend

---

## ✅ Verificación Completa

**Ejecuta este comando para verificar rápidamente:**

```bash
cd snmontery/snmontery

# Verificar .env.local
if [ -f .env.local ]; then
  echo "✅ .env.local existe"
  grep CONTRATO .env.local || echo "❌ No tiene CONTRATO_ADDRESS"
else
  echo "❌ .env.local no existe"
fi

# Verificar contract-config.ts
grep "0x0000" src/lib/contract-config.ts && echo "❌ Usando dirección por defecto (0x0000)" || echo "✅ Dirección configurada"
```

---

## 🎯 Resultado Esperado

**Si TODO está bien:**
- ✅ `.env.local` existe con `NEXT_PUBLIC_CONTRATO_ADDRESS=0x...`
- ✅ `contract-config.ts` usa la variable de entorno o tiene dirección real
- ✅ Contrato existe en el explorador de bloques
- ✅ Frontend puede crear grupos sin errores

**Si algo falta:**
- ❌ Necesitas desplegar los contratos primero
- ❌ O actualizar la dirección en la configuración

---

## 📚 Próximos Pasos

**Si NO están desplegados:**
1. Ver `DEPLOY_ARBITRUM_SEPOLIA.md` para desplegar
2. O usar Remix IDE con la guía en `GUIA_RAPIDA_PRUEBA.md`

**Si SÍ están desplegados:**
1. Verificar que la dirección esté correcta en `contract-config.ts`
2. Crear el grupo desde el frontend
3. Probar aportar fondos

---

**¿Cómo verificar ahora mismo?** Ejecuta los comandos arriba o revisa el archivo `contract-config.ts`.

