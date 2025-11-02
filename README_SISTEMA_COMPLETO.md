# 📚 Sistema Completo: Grupos de Ahorro con Aave y Multisig ERC-7913

## 🎯 Resumen Ejecutivo

Este sistema permite crear **grupos de ahorro colectivos** donde múltiples usuarios pueden contribuir fondos hacia una meta común. Los fondos se depositan automáticamente en **Aave** para generar rendimiento, y se requiere **múltiples firmas** (multisig ERC-7913) para retirar fondos.

---

## 📁 Estructura del Proyecto

```
HACKMTY/
├── contracts/
│   ├── interfaces/
│   │   └── IAaveInterfaces.sol          # Interfaces compartidas de Aave
│   │
│   ├── mocks/
│   │   └── TodosLosMocks.sol            # Contratos mock para pruebas
│   │
│   ├── erc7913/
│   │   └── GruposAhorroERC7913.sol      # Contrato principal con ERC-7913
│   │
│   └── legacy/                          # Versiones anteriores (backup)
│       ├── GruposAhorro.sol
│       ├── GruposAhorroConAave.sol
│       ├── GruposAhorroConAaveMultisig.sol
│       └── MockAave.sol
│
└── DOCUMENTACION_COMPLETA_IA.md        # Documentación detallada para IA
```

---

## 🔍 Descripción de Componentes

### 1. `contracts/interfaces/IAaveInterfaces.sol`

**Propósito:** Centraliza todas las interfaces necesarias para interactuar con Aave.

**Interfaces incluidas:**
- `IAavePool`: Pool de liquidez de Aave
  - `supply()`: Deposita activos en Aave
  - `withdraw()`: Retira activos de Aave
- `IERC20`: Interface estándar para tokens
- `IAToken`: Tokens de Aave (representan depósitos con intereses)
- `IWETH`: Wrapped ETH

**Uso:** Importado por contratos que interactúan con Aave.

---

### 2. `contracts/mocks/TodosLosMocks.sol`

**Propósito:** Simula el comportamiento de Aave para pruebas locales en Remix VM.

**Contratos incluidos:**
- `MockWETH`: Simula Wrapped ETH
- `MockAToken`: Simula tokens de Aave
- `MockAavePool`: Simula pool de Aave

**Funcionalidad:**
- `supply()`: Recibe WETH → Emite aTokens
- `withdraw()`: Quema aTokens → Devuelve WETH + intereses simulados (~0.05%)

**CRÍTICO:** Después de desplegar `MockAavePool`, SIEMPRE llamar `inicializar()`.

---

### 3. `contracts/erc7913/GruposAhorroERC7913.sol`

**Propósito:** Contrato principal con Account Abstraction y multisig.

**Contratos incluidos:**

#### `CuentaMultisigGrupo`:
- Cuenta multisig ERC-7913 por grupo
- Cada grupo tiene su propia instancia
- Requiere múltiples firmas para retiros
- Deposita automáticamente en Aave

**Funciones principales:**
- `initialize()`: Inicializa la cuenta multisig (UNA VEZ)
- `aportar()`: Deposita fondos en el grupo (se va a Aave automáticamente)
- `retirarFondos()`: Retira fondos (requiere multisig)
- `retirarMiAporte()`: Retiro individual (sin multisig)
- `obtenerBalanceTotal()`: Balance incluyendo intereses
- `calcularIntereses()`: Calcula intereses generados

#### `GruposAhorroERC7913`:
- Factory que crea grupos
- Gestiona registro de grupos
- Crea instancias de `CuentaMultisigGrupo`

**Función principal:**
- `crearGrupo()`: Crea nuevo grupo con cuenta multisig

---

## 🚀 Flujo Completo del Sistema

### Paso 1: Desplegar Contratos Base

1. **MockWETH** → Deploy (sin parámetros)
2. **MockAToken** → Deploy (sin parámetros)
3. **MockAavePool** → Deploy (con direcciones de MockWETH y MockAToken)
   - **CRÍTICO:** Llamar `inicializar()` después del deploy
4. **GruposAhorroERC7913** → Deploy (con direcciones de los 3 mocks, `usarAave: true`)

---

### Paso 2: Crear Grupo

**Función:** `crearGrupo()` en `GruposAhorroERC7913`

**Parámetros:**
- `_nombre`: "Vacaciones con Rendimiento"
- `_objetivo`: `5000000000000000000` (5 ETH)
- `_fechaObjetivo`: `2000000000` (timestamp futuro)
- `_descripcion`: "Ahorro que genera intereses"
- `_participantes`: Array de direcciones de participantes
- `_signer`: Bytes para configuración multisig (ver documentación completa)

**Resultado:**
- Retorna: `(grupoId, direcciónCuentaMultisig)`
- Se crea instancia de `CuentaMultisigGrupo`

---

### Paso 3: Aportar Fondos

**Función:** `aportar()` en `CuentaMultisigGrupo` (dirección obtenida en paso 2)

**Parámetros:** Ninguno (usa `msg.value`)

**En Remix:**
- Cambiar a Account 1 (participante)
- En "VALUE": `2000000000000000000` (2 ETH)
- Clic en `transact`

**Lo que sucede:**
- ETH recibido → Convertido a WETH → Depositado en Aave → Recibe aTokens

---

### Paso 4: Verificar Intereses

**Funciones de consulta (usar `call`):**
- `obtenerBalanceTotal()`: Balance total incluyendo intereses
- `calcularIntereses()`: Intereses generados

---

### Paso 5: Retirar Fondos

#### Opción A: Retiro Individual
- Función: `retirarMiAporte(grupoId)`
- Solo si: fecha pasó Y meta NO alcanzada

#### Opción B: Retiro Completo con Multisig
- Función: `retirarFondos(destinatario)`
- Requiere: múltiples firmas a través del entry point
- Solo si: meta alcanzada O fecha pasó

---

## 📋 Datos Exactos para Pruebas

### Crear Grupo:
```
_nombre: "Vacaciones con Rendimiento"
_objetivo: 5000000000000000000
_fechaObjetivo: 2000000000
_descripcion: "Ahorro que genera intereses"
_participantes: [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]
_signer: [bytes - ver documentación para formato]
```

### Aportar:
```
VALUE: 2000000000000000000  (2 ETH)
```

### Verificar:
```
obtenerBalanceTotal() → call
calcularIntereses() → call
```

---

## ✅ Checklist de Despliegue

### Preparación:
- [ ] Archivos copiados a Remix
- [ ] Compilación exitosa

### Despliegue:
- [ ] MockWETH desplegado
- [ ] MockAToken desplegado
- [ ] MockAavePool desplegado
- [ ] **`inicializar()` llamado en MockAavePool** ✅
- [ ] GruposAhorroERC7913 desplegado

### Probar:
- [ ] Grupo creado
- [ ] Aporte realizado
- [ ] Intereses verificados
- [ ] Retiro probado

---

## 📚 Documentación Detallada

Para información completa, consultar:
- **`DOCUMENTACION_COMPLETA_IA.md`**: Documentación técnica detallada
- **`GUIA_DESPLIEGUE_COMPLETA_IA.md`**: Guía paso a paso de despliegue

---

**Todo está organizado y documentado para que una IA pueda desplegar el sistema completo.** 🚀

