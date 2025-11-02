# 🤖 Instrucciones Completas para IA: Desplegar Sistema de Grupos de Ahorro

## 📋 Resumen Ejecutivo

**Sistema:** Grupos de Ahorro con Aave y Multisig ERC-7913

**Propósito:** Permitir que grupos de usuarios ahorren colectivamente hacia una meta, con fondos que generan rendimiento automático en Aave, y retiros que requieren múltiples firmas.

**Archivos Principales:** 2 archivos de smart contracts

---

## 📁 Estructura de Archivos del Proyecto

```
HACKMTY/
└── contracts/
    ├── interfaces/
    │   └── IAaveInterfaces.sol          # Interfaces compartidas de Aave
    ├── mocks/
    │   └── TodosLosMocks.sol            # MockWETH, MockAToken, MockAavePool (para pruebas)
    ├── erc7913/
    │   └── GruposAhorroERC7913.sol      # Contrato principal (CuentaMultisigGrupo + GruposAhorroERC7913)
    └── legacy/                          # Versiones anteriores (no usar en despliegue)
        ├── GruposAhorro.sol
        ├── GruposAhorroConAave.sol
        ├── GruposAhorroConAaveMultisig.sol
        └── MockAave.sol
```

---

## 🔧 Descripción Técnica de Cada Componente

### 1. `contracts/interfaces/IAaveInterfaces.sol`

**Tipo:** Interface Solidity  
**Versión:** 0.8.20  
**Ubicación:** `contracts/interfaces/IAaveInterfaces.sol`

**Contenido:**
- Define 4 interfaces:
  - `IAavePool`: Para interactuar con el pool de Aave
    - `supply()`: Deposita activos en Aave
    - `withdraw()`: Retira activos de Aave
  - `IERC20`: Interface estándar para tokens ERC-20
  - `IAToken`: Interface para tokens de Aave (hereda de IERC20)
  - `IWETH`: Interface para Wrapped ETH

**Uso:** Importado por contratos que interactúan con Aave.

---

### 2. `contracts/mocks/TodosLosMocks.sol`

**Tipo:** Contratos Mock Solidity  
**Versión:** 0.8.20  
**Ubicación:** `contracts/mocks/TodosLosMocks.sol`

**Contratos incluidos:**

#### `MockWETH` (Líneas 11-45):
**Simula:** Wrapped ETH

**Funciones:**
- `deposit()`: Recibe ETH, actualiza `balanceOf[msg.sender]`
- `withdraw(uint256 amount)`: Reduce balance, transfiere ETH
- `approve(address spender, uint256 amount)`: Configura allowance
- `transfer(address to, uint256 amount)`: Transfiere WETH
- `transferFrom(address from, address to, uint256 amount)`: Transfiere desde cuenta autorizada

**Variables públicas:**
- `balanceOf`: Mapping dirección => balance WETH
- `allowance`: Mapping (propietario => (spender => cantidad))

**Constructor:** Ninguno (contrato simple)

---

#### `MockAToken` (Líneas 47-84):
**Simula:** Tokens de Aave (aTokens)

**Funciones:**
- `setPool(address _pool)`: Configura qué contrato puede mintear/quemar
- `mint(address to, uint256 amount)`: Crea aTokens (solo pool, línea 61-65)
- `burn(address from, uint256 amount)`: Quema aTokens (solo pool, línea 67-72)
- `transfer(address to, uint256 amount)`: Transfiere aTokens
- `approve(address spender, uint256 amount)`: Aprueba gasto

**Variables públicas:**
- `balanceOf`: Mapping dirección => balance aTokens
- `totalSupply`: Total de aTokens
- `pool`: Dirección autorizada para mintear/quemar

**Constructor:** Ninguno (pool inicializa como msg.sender)

**NOTA:** Solo el `pool` configurado puede llamar `mint()` y `burn()`.

---

#### `MockAavePool` (Líneas 86-120):
**Simula:** Pool de liquidez de Aave

**Funciones:**
- `inicializar()`: **CRÍTICO** - Configura el pool en MockAToken. DEBE llamarse después del deploy.
- `supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)`:
  - Transfiere WETH del llamador al pool (línea 106)
  - Emite aTokens al destinatario (línea 107)
- `withdraw(address asset, uint256 amount, address to)`:
  - Quema aTokens del llamador (línea 115)
  - Transfiere WETH + intereses simulados al destinatario (línea 116)
  - Intereses simulados: `amount + (amount * 5 / 10000)` (~0.05% por bloque)

**Variables públicas:**
- `weth`: Referencia a MockWETH
- `aWETH`: Referencia a MockAToken

**Constructor:**
- `MockAavePool(address _weth, address _aWETH)`
- Configura referencias pero NO llama `inicializar()` automáticamente

**CRÍTICO:** Después de desplegar `MockAavePool`, SIEMPRE llamar `inicializar()`. Si no, obtendrás error "Only pool can mint".

---

### 3. `contracts/erc7913/GruposAhorroERC7913.sol`

**Tipo:** Contratos Principales Solidity  
**Versión:** 0.8.24  
**Ubicación:** `contracts/erc7913/GruposAhorroERC7913.sol`

**Dependencias:**
- `@openzeppelin/community-contracts/account/Account.sol`
- `@openzeppelin/contracts/utils/cryptography/EIP712.sol`
- `@openzeppelin/community-contracts/utils/cryptography/signers/ERC7739.sol`
- `@openzeppelin/community-contracts/account/extensions/ERC7821.sol`
- `@openzeppelin/community-contracts/utils/cryptography/signers/SignerERC7913.sol`
- `../../interfaces/IAaveInterfaces.sol` (interfaces locales)

**Contratos incluidos:**

---

#### `CuentaMultisigGrupo` (Líneas 14-350):

**Herencia:**
- `Account`: Base de cuenta abstracta (ERC-4337/7913)
- `SignerERC7913`: Sistema de signatarios múltiples
- `ERC7739`: Estándar multisig
- `ERC7821`: Autorización de ejecución
- `ERC721Holder`, `ERC1155Holder`: Soporte NFTs
- `Initializable`: Inicialización única

**Variables de Estado Públicas:**
- `grupoId`: ID del grupo (uint256)
- `grupoManager`: Dirección del contrato principal (address)
- `objetivo`: Meta en wei (uint256)
- `totalRecaudado`: Total depositado originalmente (uint256)
- `totalEnAave`: Total actualmente en Aave (uint256)
- `fechaObjetivo`: Timestamp límite (uint256)
- `activo`: Si el grupo está activo (bool)
- `metaAlcanzada`: Si se alcanzó la meta (bool)
- `participantes[]`: Array de participantes (address[])
- `aportes`: Mapping participante => cantidad (mapping(address => uint256))

**Variables Privadas:**
- `aavePool`: Referencia a IAavePool (immutable)
- `weth`: Referencia a IWETH (immutable)
- `aWETH`: Referencia a IAToken (immutable)
- `usarAave`: Flag para habilitar/deshabilitar Aave (bool)

**Funciones Públicas:**

1. **`constructor(address _aavePool, address _weth, address _aWETH, bool _usarAave)`**
   - Inicializa EIP712 con nombre "CuentaMultisigGrupo" y versión "1"
   - Configura direcciones de Aave (aavePool, weth, aWETH)
   - Habilita/deshabilita Aave (usarAave)

2. **`initialize(bytes memory _signer, uint256 _grupoId, address _grupoManager, address[] memory _participantes, uint256 _objetivo, uint256 _fechaObjetivo)`**
   - **Modificador:** `initializer` (solo se puede llamar UNA VEZ)
   - Configura signatarios multisig: `_setSigner(_signer)`
   - Inicializa estado del grupo
   - Agrega participantes al array
   - Agrega esta cuenta como participante
   - Emite evento `GrupoInicializado`

3. **`aportar()`** (payable, externa)
   - **Validaciones:**
     - Grupo activo: `require(activo, "El grupo no esta activo")`
     - Cantidad > 0: `require(msg.value > 0, "Debes enviar una cantidad mayor a 0")`
     - Meta no alcanzada: `require(!metaAlcanzada, "La meta ya fue alcanzada")`
     - Fecha no pasada: `require(block.timestamp <= fechaObjetivo, "La fecha objetivo ya paso")`
     - Es participante: `require(_esParticipante(msg.sender), "No eres participante de este grupo")`
   
   - **Proceso:**
     1. Registra aporte: `aportes[msg.sender] += msg.value`
     2. Actualiza: `totalRecaudado += msg.value`
     3. Si `usarAave == true`:
        - Llama `_depositarEnAave(msg.value)`:
          - Convierte ETH → WETH: `weth.deposit{value: msg.value}()`
          - Aprueba: `weth.approve(aavePool, msg.value)`
          - Deposita: `aavePool.supply(weth, msg.value, address(this), 0)`
        - Actualiza: `totalEnAave += msg.value`
        - Emite: `FondosDepositadosEnAave(msg.value)`
     4. Verifica meta: Si `obtenerBalanceTotal() >= objetivo` → marca `metaAlcanzada = true` y emite `MetaAlcanzada`
     5. Emite: `AporteRealizado`

4. **`retirarFondos(address _destinatario)`** (externa)
   - **Modificador:** `onlyEntryPointOrSelf` (requiere entry point o cuenta misma)
   - **Validaciones:**
     - Meta alcanzada O fecha pasada: `require(metaAlcanzada || block.timestamp > fechaObjetivo, ...)`
     - Destinatario válido: `require(_destinatario != address(0), "Direccion invalida")`
     - Hay fondos: `require(obtenerBalanceTotal() > 0, "No hay fondos para retirar")`
   
   - **Proceso:**
     1. Si `usarAave == true`:
        - Llama `_retirarDeAave(type(uint256).max)`:
          - Obtiene balance: `aWETH.balanceOf(address(this))`
          - Retira de Aave: `aavePool.withdraw(weth, cantidad, address(this))`
          - Convierte WETH → ETH: `weth.withdraw(cantidadRetirada)`
        - Calcula intereses: `cantidadRetirada - totalRecaudado`
        - Emite: `FondosRetiradosDeAave(cantidadRetirada)`
     2. Transfiere ETH al destinatario: `payable(_destinatario).call{value: cantidadFinal}("")`
     3. Actualiza estado: `activo = false`, limpia contadores
     4. Emite: `FondoRetirado`

5. **`retirarMiAporte(uint256 _grupoId)`** (externa)
   - **Validaciones:**
     - ID correcto: `require(_grupoId == grupoId, "ID de grupo incorrecto")`
     - Fecha pasada: `require(block.timestamp > fechaObjetivo, "La fecha objetivo no ha pasado")`
     - Meta NO alcanzada: `require(!metaAlcanzada, "La meta fue alcanzada, se requiere multisig para retirar")`
     - Es participante: `require(_esParticipante(msg.sender), "No eres participante")`
     - Tiene aportes: `require(aportes[msg.sender] > 0, "No tienes aportes para retirar")`
   
   - **Proceso:**
     1. Calcula porcentaje: `(aporteOriginal * 100) / totalRecaudado`
     2. Calcula aporte con intereses: `(balanceTotal * porcentaje) / 100`
     3. Si está en Aave, retira proporcionalmente
     4. Transfiere al participante
     5. Actualiza estado
     6. Emite evento

6. **`obtenerBalanceTotal()`** (pública, view)
   - Si `usarAave == true`: Retorna `aWETH.balanceOf(address(this))`
   - Si `usarAave == false`: Retorna `address(this).balance`

7. **`calcularIntereses()`** (externa, view)
   - Retorna: `obtenerBalanceTotal() - totalRecaudado`
   - Si negativo, retorna 0

8. **`obtenerInfoGrupo()`** (externa, view)
   - Retorna toda la información del grupo como tupla

**Funciones Internas:**
- `_depositarEnAave(uint256 _cantidad)`: Convierte ETH → WETH → Deposita en Aave
- `_retirarDeAave(uint256 _cantidadMaxima)`: Retira de Aave → Convierte WETH → ETH
- `_esParticipante(address _direccion)`: Verifica si una dirección es participante
- `_erc7821AuthorizedExecutor()`: Permite entry point como ejecutor autorizado

**Eventos:**
- `GrupoInicializado`: Cuando se inicializa la cuenta
- `AporteRealizado`: Cuando alguien aporta
- `MetaAlcanzada`: Cuando se alcanza la meta
- `FondoRetirado`: Cuando se retiran fondos
- `FondosDepositadosEnAave`: Cuando se deposita en Aave
- `FondosRetiradosDeAave`: Cuando se retira de Aave

---

#### `GruposAhorroERC7913` (Líneas 352-473):

**Tipo:** Factory Contract

**Variables de Estado:**
- `totalGrupos`: Contador de grupos (uint256)
- `cuentasGrupos`: Mapping grupoId => dirección cuenta multisig (mapping(uint256 => address))
- `gruposPorUsuario`: Mapping usuario => array de grupoIds (mapping(address => uint256[]))
- `aavePool`: Referencia a IAavePool (immutable)
- `weth`: Referencia a IWETH (immutable)
- `aWETH`: Referencia a IAToken (immutable)
- `usarAave`: Flag para habilitar Aave (bool)
- `cuentaFactory`: Dirección de factory (address)

**Funciones:**

1. **`constructor(address _aavePool, address _weth, address _aWETH, bool _usarAave, address _cuentaFactory)`**
   - Configura direcciones de Aave
   - Habilita/deshabilita Aave
   - Configura factory (puede ser address(0) para pruebas)

2. **`crearGrupo(string memory _nombre, uint256 _objetivo, uint256 _fechaObjetivo, string memory _descripcion, address[] memory _participantes, bytes memory _signer)`**
   - **Validaciones:**
     - Objetivo > 0
     - Fecha en el futuro
     - Nombre no vacío
     - Al menos un participante
   
   - **Proceso:**
     1. Incrementa `totalGrupos` y asigna `grupoId`
     2. Crea nueva instancia: `new CuentaMultisigGrupo(aavePool, weth, aWETH, usarAave)`
     3. Llama `initialize()` en la cuenta con todos los parámetros
     4. Registra: `cuentasGrupos[grupoId] = cuenta`
     5. Registra: `gruposPorUsuario[creador].push(grupoId)`
     6. Emite: `GrupoCreado`
     7. Retorna: `(grupoId, cuenta)`

3. **`obtenerCuentaGrupo(uint256 _grupoId)`** (externa, view)
   - Retorna dirección de la cuenta multisig del grupo

4. **`obtenerGruposPorUsuario(address _usuario)`** (externa, view)
   - Retorna array de IDs de grupos del usuario

**Eventos:**
- `GrupoCreado`: Cuando se crea un grupo
- `ParticipanteAgregado`: Cuando se agrega un participante (no usado en este contrato, se hace en la cuenta)

---

## 🚀 Proceso de Despliegue Paso a Paso

### Configuración Inicial

**Entorno:** Remix IDE (https://remix.ethereum.org/)  
**Environment:** Remix VM (Cancun)  
**Versión Solidity:** 0.8.20 para mocks, 0.8.24 para ERC-7913

---

### Paso 1: Copiar Archivos a Remix

#### Archivo 1: `TodosLosMocks.sol`

**Acción:**
1. Crear archivo: `contracts/TodosLosMocks.sol` en Remix
2. Copiar TODO el contenido de `contracts/mocks/TodosLosMocks.sol`
3. Guardar (Ctrl+S o Cmd+S)

**Verificación:** El archivo debe tener ~122 líneas y contener 3 contratos: MockWETH, MockAToken, MockAavePool

---

#### Archivo 2: `GruposAhorroERC7913.sol`

**Acción:**
1. Crear archivo: `contracts/GruposAhorroERC7913.sol` en Remix
2. Copiar TODO el contenido de `contracts/erc7913/GruposAhorroERC7913.sol`
3. **Si hay errores de import:**
   - Opción A: Crear también `contracts/interfaces/IAaveInterfaces.sol` en Remix y copiar contenido
   - Opción B: Reemplazar `import "../../interfaces/IAaveInterfaces.sol";` con las interfaces directamente en el archivo
4. Guardar

**Verificación:** El archivo debe tener ~473 líneas y contener 2 contratos: CuentaMultisigGrupo, GruposAhorroERC7913

---

#### Archivo 3 (Opcional): `IAaveInterfaces.sol`

**Solo necesario si:** `GruposAhorroERC7913.sol` usa import de interfaces

**Acción:**
1. Crear carpeta: `contracts/interfaces/` en Remix
2. Crear archivo: `contracts/interfaces/IAaveInterfaces.sol`
3. Copiar contenido de `contracts/interfaces/IAaveInterfaces.sol`
4. Guardar

---

### Paso 2: Compilar Contratos

#### Compilar `TodosLosMocks.sol`:

1. Ir a pestaña **"Solidity Compiler"**
2. Seleccionar versión: **0.8.20**
3. Clic en **"Compile TodosLosMocks.sol"**
4. Verificar: ✅ Verde sin errores
5. Verificar: Aparecen 3 contratos en el dropdown de deploy

---

#### Compilar `GruposAhorroERC7913.sol`:

1. Seleccionar versión: **0.8.24**
2. Clic en **"Compile GruposAhorroERC7913.sol"**
3. **Si hay errores de dependencias de OpenZeppelin:**
   - Opción A: Instalar dependencias en Remix (si es posible)
   - Opción B: Usar `contracts/legacy/GruposAhorroConAaveMultisig.sol` (no requiere ERC-7913)
4. Verificar: ✅ Verde sin errores
5. Verificar: Aparecen 2 contratos en el dropdown: CuentaMultisigGrupo, GruposAhorroERC7913

---

### Paso 3: Desplegar Contratos Mock

Ir a pestaña **"Deploy & Run Transactions"**

#### 3.1 Desplegar MockWETH

- **Contrato:** `MockWETH` (del archivo TodosLosMocks.sol)
- **Parámetros del constructor:** Ninguno
- **Acción:** Clic en **"Deploy"**
- **Resultado esperado:** Contrato aparece en "Deployed Contracts"
- **Verificar:** `status: 0x1 Transaction mined and execution succeed`
- **Guardar dirección:** Ejemplo: `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4`

**Dirección obtenida:** `_________________`

---

#### 3.2 Desplegar MockAToken

- **Contrato:** `MockAToken` (del archivo TodosLosMocks.sol)
- **Parámetros del constructor:** Ninguno
- **Acción:** Clic en **"Deploy"**
- **Resultado esperado:** Contrato aparece en "Deployed Contracts"
- **Verificar:** `status: 0x1 Transaction mined and execution succeed`
- **Guardar dirección:** Ejemplo: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2`

**Dirección obtenida:** `_________________`

---

#### 3.3 Desplegar MockAavePool

- **Contrato:** `MockAavePool` (del archivo TodosLosMocks.sol)
- **Parámetros del constructor:**
  - `_weth`: Dirección de MockWETH (paso 3.1)
  - `_aWETH`: Dirección de MockAToken (paso 3.2)
- **Acción:** Clic en **"Deploy"**
- **Resultado esperado:** Contrato aparece en "Deployed Contracts"
- **Verificar:** `status: 0x1 Transaction mined and execution succeed`

**CRÍTICO - Paso siguiente:**

1. **Expandir** `MockAavePool` desplegado
2. **Buscar** función `inicializar` (sin parámetros)
3. **Clic en** `inicializar` (o `transact`)
4. **Verificar:** `status: 0x1 Transaction mined and execution succeed`
5. **Guardar dirección:** Ejemplo: `0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692`

**Dirección obtenida:** `_________________`

**SI NO LLAMAS `inicializar()`, OBTENDRÁS ERROR "Only pool can mint" AL INTENTAR USAR EL CONTRATO.**

---

### Paso 4: Desplegar Contrato Principal

#### 4.1 Desplegar GruposAhorroERC7913

- **Contrato:** `GruposAhorroERC7913` (del archivo GruposAhorroERC7913.sol)
- **Parámetros del constructor:**
  - `_aavePool`: Dirección de MockAavePool (paso 3.3)
  - `_weth`: Dirección de MockWETH (paso 3.1)
  - `_aWETH`: Dirección de MockAToken (paso 3.2)
  - `_usarAave`: `true` (boolean, sin comillas)
  - `_cuentaFactory`: `address(0)` o `0x0000000000000000000000000000000000000000` (para pruebas simples)
- **Acción:** Clic en **"Deploy"**
- **Resultado esperado:** Contrato aparece en "Deployed Contracts"
- **Verificar:** `status: 0x1 Transaction mined and execution succeed`
- **Guardar dirección**

**Dirección obtenida:** `_________________`

---

### Paso 5: Crear Primer Grupo

**Función:** `crearGrupo()` en `GruposAhorroERC7913`

**Parámetros:**

1. **`_nombre`** (string): `"Vacaciones con Rendimiento"`

2. **`_objetivo`** (uint256): `5000000000000000000`
   - Significa: 5 ETH
   - Conversión: 1 ETH = 1000000000000000000 wei
   - 5 ETH = 5000000000000000000 wei

3. **`_fechaObjetivo`** (uint256): `2000000000`
   - Significa: Timestamp de fecha futura
   - Timestamp actual (nov 2024): ~1730000000
   - `2000000000` = año 2033 (seguro para pruebas)

4. **`_descripcion`** (string): `"Ahorro que genera intereses automáticamente"`

5. **`_participantes`** (address[]): Array de direcciones
   - **Obtener direcciones:** Del dropdown "Account" en Remix
   - **Ejemplo:**
     ```
     [
       0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,  // Account 0
       0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2   // Account 1
     ]
     ```
   - **Nota:** Puedes agregar más direcciones del dropdown "Account"

6. **`_signer`** (bytes): Configuración multisig
   - **Para pruebas simples en Remix VM:**
     - Puedes usar un formato simplificado
     - Ejemplo mínimo: `abi.encode([direcciones], umbral)`
   - **Formato completo (depende de SignerERC7913):**
     ```solidity
     // Ejemplo simplificado para pruebas
     bytes memory signerBytes = abi.encode(
         [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
          0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2],  // 2 signatarios
         1  // umbral: se necesita 1 de 2
     );
     ```
   - **Nota:** El formato exacto depende de la implementación de `SignerERC7913`. Para pruebas, un formato simple puede funcionar.

**Ejecución:**

1. **Expandir** `GruposAhorroERC7913` desplegado
2. **Buscar** función `crearGrupo`
3. **Ingresar** todos los parámetros
4. **Clic en** `transact`
5. **Verificar:** `status: 0x1 Transaction mined and execution succeed`
6. **En decoded output o logs:** Buscar valores retornados: `(grupoId, cuenta)`
7. **Guardar ambos:**
   - `grupoId`: Probablemente `0` (primer grupo)
   - `cuenta`: Dirección de la cuenta multisig creada

**Direcciones obtenidas:**
- `grupoId`: `_______` (probablemente `0`)
- `cuenta`: `_________________` (dirección de CuentaMultisigGrupo)

**Lo que sucede internamente:**
1. Valida parámetros (objetivo > 0, fecha futura, nombre no vacío, participantes > 0)
2. Incrementa `totalGrupos` y asigna `grupoId`
3. Crea nueva instancia: `new CuentaMultisigGrupo(aavePool, weth, aWETH, usarAave)`
4. Llama `initialize()` en la cuenta con todos los parámetros
5. Configura signatarios multisig: `_setSigner(_signer)`
6. Registra: `cuentasGrupos[grupoId] = cuenta`
7. Registra: `gruposPorUsuario[creador].push(grupoId)`
8. Emite evento `GrupoCreado`
9. Retorna `(grupoId, cuenta)`

---

### Paso 6: Aportar Fondos

**IMPORTANTE:** Los aportes se hacen en la **cuenta multisig**, NO en el contrato principal.

**Función:** `aportar()` en `CuentaMultisigGrupo`

**Pasos:**

1. **Obtener dirección de la cuenta multisig:**
   - En `GruposAhorroERC7913`, llamar `obtenerCuentaGrupo(0)` (o el grupoId obtenido)
   - Usar `call` (no `transact`)
   - **Copiar dirección retornada**

2. **Acceder a la cuenta multisig:**
   - **Opción A:** Si aparece en "Deployed Contracts", expandir
   - **Opción B:** En Remix, usar "At Address":
     - Copiar dirección de la cuenta
     - Seleccionar contrato `CuentaMultisigGrupo`
     - Clic en "At Address"
     - Ingresar dirección
     - Clic en "At Address"
     - El contrato aparece en "Deployed Contracts"

3. **Expandir** `CuentaMultisigGrupo` desplegada

4. **Buscar** función `aportar`

5. **Parámetros de la función:** Ninguno (la función no tiene parámetros, usa `msg.value`)

6. **En el campo "VALUE"** (arriba, junto a la unidad "Wei" o "Ether"):
   - Ingresar: `2000000000000000000`
   - Significa: 2 ETH
   - Conversión: 1 ETH = 1000000000000000000 wei

7. **Cambiar a Account 1** (si quieres que otro participante aporte):
   - Del dropdown "Account" (arriba)
   - Seleccionar "Account 1" o la dirección del participante

8. **Clic en** `transact` (NO `call`)

**Verificación:**

- **Consola:** Buscar eventos emitidos
  - `AporteRealizado`: Con valores `(participante, cantidad, totalRecaudado, totalEnAave)`
  - `FondosDepositadosEnAave`: Si se depositó en Aave
  - `MetaAlcanzada`: Si se alcanzó la meta (opcional)

- **Estado:** `status: 0x1 Transaction mined and execution succeed`

**Lo que sucede internamente:**
1. Valida que el grupo está activo: `require(activo, ...)`
2. Valida que `msg.value > 0`
3. Valida que la meta no está alcanzada: `require(!metaAlcanzada, ...)`
4. Valida que la fecha no pasó: `require(block.timestamp <= fechaObjetivo, ...)`
5. Valida que es participante: `require(_esParticipante(msg.sender), ...)`
6. Registra aporte: `aportes[msg.sender] += msg.value`
7. Actualiza: `totalRecaudado += msg.value`
8. Si `usarAave == true`:
   - Llama `_depositarEnAave(msg.value)`:
     - `weth.deposit{value: msg.value}()`: Convierte ETH → WETH
     - `weth.approve(aavePool, msg.value)`: Aprueba a Aave
     - `aavePool.supply(weth, msg.value, address(this), 0)`: Deposita en Aave
     - Recibe aTokens
   - Actualiza: `totalEnAave += msg.value`
   - Emite: `FondosDepositadosEnAave(msg.value)`
9. Verifica meta: Si `obtenerBalanceTotal() >= objetivo`:
   - Marca: `metaAlcanzada = true`
   - Emite: `MetaAlcanzada(grupoId, balanceTotal)`
10. Emite: `AporteRealizado(grupoId, msg.sender, msg.value, totalRecaudado, totalEnAave)`

---

### Paso 7: Verificar Estado e Intereses

**Funciones de consulta (usar `call`, NO `transact`):**

#### 7.1 Verificar Balance Total

- **Función:** `obtenerBalanceTotal()` en `CuentaMultisigGrupo`
- **Parámetros:** Ninguno
- **Acción:** Clic en `call`
- **Resultado esperado:** Balance total en wei
  - Si aportaste 2 ETH y está en Aave: `2000000000000000000` (inicialmente)
  - Después de varios bloques: puede ser mayor por intereses simulados (ej: `2008000000000000000`)

**Interpretación:**
- `2000000000000000000` = 2 ETH (sin intereses aún)
- `2008000000000000000` = 2.008 ETH (con ~0.008 ETH de intereses)

---

#### 7.2 Calcular Intereses Generados

- **Función:** `calcularIntereses()` en `CuentaMultisigGrupo`
- **Parámetros:** Ninguno
- **Acción:** Clic en `call`
- **Resultado esperado:** Intereses en wei
  - Inicialmente: `0` (aún no hay intereses)
  - Después de varios bloques: `8000000000000000` (0.008 ETH aproximadamente)

**Interpretación:**
- `0` = No hay intereses generados aún
- `8000000000000000` = 0.008 ETH de intereses generados

**Cálculo:**
```
Intereses = Balance Total - Aportes Originales
Ejemplo: 2008000000000000000 - 2000000000000000000 = 8000000000000000
```

---

#### 7.3 Verificar Info del Grupo

- **Función:** `obtenerInfoGrupo()` en `CuentaMultisigGrupo`
- **Parámetros:** Ninguno
- **Acción:** Clic en `call`
- **Resultado esperado:** Tupla con toda la información del grupo

**Valores retornados:**
- `id`: ID del grupo
- `manager`: Dirección del contrato principal
- `objetivoGrupo`: Meta en wei
- `totalRecaudadoGrupo`: Total depositado originalmente
- `totalEnAaveGrupo`: Total actualmente en Aave
- `fechaObjetivoGrupo`: Timestamp límite
- `activoGrupo`: Si está activo (true/false)
- `metaAlcanzadaGrupo`: Si se alcanzó la meta (true/false)
- `participantesGrupo`: Array de direcciones de participantes

---

#### 7.4 Verificar Aporte de Participante

- **Función:** `obtenerAporte(address _participante)` en `CuentaMultisigGrupo`
- **Parámetros:** `_participante`: Dirección del participante (ej: Account 1)
- **Acción:** Clic en `call`
- **Resultado esperado:** Aporte del participante en wei

**Ejemplo:**
- Si Account 1 aportó 2 ETH: `2000000000000000000`

---

### Paso 8: Retirar Fondos

#### Opción A: Retiro Individual (sin multisig)

**Condiciones necesarias:**
- `block.timestamp > fechaObjetivo` (la fecha objetivo pasó)
- `metaAlcanzada == false` (la meta NO fue alcanzada)
- El participante tiene aportes

**Función:** `retirarMiAporte(uint256 _grupoId)` en `CuentaMultisigGrupo`

**Parámetros:**
- `_grupoId`: `0` (o el ID del grupo)

**Pasos:**

1. **Cambiar a la cuenta del participante** (ej: Account 1)
   - Del dropdown "Account" en Remix

2. **Expandir** `CuentaMultisigGrupo` desplegada

3. **Buscar** función `retirarMiAporte`

4. **Ingresar parámetros:**
   - `_grupoId`: `0` (o el ID del grupo)

5. **Clic en** `transact`

**Verificación:**
- **Estado:** `status: 0x1 Transaction mined and execution succeed`
- **Eventos:** `FondoRetirado` con cantidad retirada e intereses

**Lo que sucede internamente:**
1. Valida que `_grupoId == grupoId`
2. Valida que `block.timestamp > fechaObjetivo`
3. Valida que `metaAlcanzada == false`
4. Valida que es participante
5. Obtiene aporte original: `aportes[msg.sender]`
6. Calcula porcentaje: `(aporteOriginal * 100) / totalRecaudado`
7. Calcula aporte con intereses: `(obtenerBalanceTotal() * porcentaje) / 100`
8. Si está en Aave:
   - Calcula cantidad a retirar: `(balanceAave * porcentaje) / 100`
   - Retira de Aave: `aavePool.withdraw(weth, cantidad, address(this))`
   - Convierte WETH → ETH: `weth.withdraw(cantidad)`
9. Actualiza estado: `aportes[msg.sender] = 0`, reduce contadores
10. Transfiere ETH al participante: `payable(msg.sender).call{value: miAporteConIntereses}("")`
11. Emite evento `FondoRetirado`

---

#### Opción B: Retiro Completo con Multisig

**Condiciones necesarias:**
- `metaAlcanzada == true` O `block.timestamp > fechaObjetivo`
- Se necesitan múltiples firmas de participantes/signatarios
- Ejecución a través del entry point de ERC-7913

**Función:** `retirarFondos(address _destinatario)` en `CuentaMultisigGrupo`

**Acceso:** Solo a través del entry point (modifier `onlyEntryPointOrSelf`)

**Para pruebas simples en Remix VM:**

Como el entry point de ERC-7913 requiere configuración compleja, puedes:

**Opción B1:** Usar versión simplificada `GruposAhorroConAaveMultisig.sol` (no requiere entry point)

**Opción B2:** Modificar temporalmente `retirarFondos()` para pruebas:
- Remover el modificador `onlyEntryPointOrSelf`
- Agregar validación alternativa para pruebas

**Para producción (con Entry Point real):**

**Proceso off-chain:**
1. Participantes firman la transacción fuera de blockchain
2. Cada firma incluye: hash de la operación, nonce, etc.

**Proceso on-chain:**
1. Ejecutar a través del entry point:
   ```solidity
   entryPoint.executeBatch([
       {
           target: cuentaMultisig,
           value: 0,
           data: abi.encodeWithSelector(
               CuentaMultisigGrupo.retirarFondos.selector,
               destinatario
           )
       }
   ], [firma1, firma2, ...])  // Array de firmas de múltiples participantes
   ```

2. El entry point:
   - Verifica que hay suficientes firmas válidas
   - Verifica el nonce
   - Ejecuta `retirarFondos()` en la cuenta multisig

3. La función `retirarFondos()`:
   - Valida condiciones (meta alcanzada O fecha pasada)
   - Si está en Aave:
     - Obtiene balance: `aWETH.balanceOf(address(this))`
     - Retira de Aave: `aavePool.withdraw(weth, cantidad, address(this))`
     - Convierte WETH → ETH: `weth.withdraw(cantidadRetirada)`
   - Calcula intereses: `cantidadRetirada - totalRecaudado`
   - Transfiere ETH al destinatario
   - Actualiza estado: `activo = false`, limpia contadores
   - Emite eventos

---

## 📊 Valores de Ejemplo para Pruebas

### Timestamps:
```
2000000000        # Muy futuro (año 2033) - Usar para pruebas
1735689600        # 31 diciembre 2024
1704067200        # 1 enero 2024
```

### Cantidades en Wei:
```
1000000000000000000      = 1 ETH
2000000000000000000      = 2 ETH
5000000000000000000      = 5 ETH
10000000000000000000    = 10 ETH
```

### Direcciones de Ejemplo (Remix VM):
```
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4  # Account 0
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2   # Account 1
0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db   # Account 2
```

**Nota:** En Remix, usar direcciones reales del dropdown "Account".

---

## ⚠️ Problemas Comunes y Soluciones

### Error: "Missing dependency @openzeppelin/community-contracts"

**Causa:** `GruposAhorroERC7913.sol` requiere dependencias de OpenZeppelin que no están disponibles en Remix.

**Solución A (Recomendada para pruebas simples):**
- Usar `contracts/legacy/GruposAhorroConAaveMultisig.sol` en lugar de ERC-7913
- No requiere dependencias especiales
- Tiene multisig tradicional (más simple)

**Solución B:**
- Instalar dependencias en Remix (si es posible)
- O usar Hardhat localmente con `npm install @openzeppelin/community-contracts`

**Solución C:**
- Para pruebas, copiar las dependencias necesarias directamente en Remix

---

### Error: "Only pool can mint" en MockAToken

**Causa:** No se llamó `inicializar()` en `MockAavePool` después del deploy.

**Solución:**
1. Expandir `MockAavePool` desplegado
2. Buscar función `inicializar`
3. Llamar `inicializar()` (sin parámetros)
4. Verificar: `status: 0x1 Transaction mined and execution succeed`

**Verificación:** Después de `inicializar()`, MockAavePool puede mintear tokens.

---

### Error: "Insufficient allowance" al depositar en Aave

**Causa:** El contrato no aprobó suficiente WETH antes de depositar.

**Verificar en código:**
- En `_depositarEnAave()`, debe llamar `weth.approve(aavePool, cantidad)` antes de `aavePool.supply()`

**Solución:**
- Verificar que `weth.approve()` se está llamando correctamente
- Verificar que el monto aprobado es >= al monto a depositar

---

### Intereses aparecen en cero

**Causas posibles:**

1. **No se aportaron fondos aún**
   - Verificar: `obtenerBalanceTotal()` debe ser > 0
   - Verificar: `totalRecaudado` debe ser > 0
   - **Solución:** Aportar fondos primero

2. **Fondos recién depositados**
   - En mocks, los intereses son simulados y crecen lentamente
   - Los intereses aparecen después de varios bloques
   - **Solución:** Esperar algunos bloques y volver a verificar

3. **Aave deshabilitado**
   - Verificar: `usarAave` debe ser `true`
   - Verificar: `totalEnAave` debe ser > 0
   - **Solución:** Verificar que se desplegó con `usarAave = true`

---

### No puedo retirar fondos

**Para retiro individual (`retirarMiAporte`):**
- Verificar: `block.timestamp > fechaObjetivo` (fecha pasó)
- Verificar: `metaAlcanzada == false` (meta NO alcanzada)
- Verificar: Participante tiene aportes
- **Solución:** Asegurar que todas las condiciones se cumplen

**Para retiro completo (`retirarFondos`):**
- Verificar: `metaAlcanzada == true` O `block.timestamp > fechaObjetivo`
- Verificar: Hay fondos para retirar
- Verificar: Se tienen suficientes firmas (para ERC-7913)
- **Solución:** Para pruebas simples, usar versión sin ERC-7913 o modificar temporalmente

---

## ✅ Checklist de Despliegue Completo

### Preparación:
- [ ] Archivos copiados a Remix
  - [ ] `TodosLosMocks.sol`
  - [ ] `GruposAhorroERC7913.sol` (o versión alternativa si hay problemas)
  - [ ] `IAaveInterfaces.sol` (si es necesario)
- [ ] Versión Solidity correcta seleccionada (0.8.20 para mocks, 0.8.24 para ERC-7913)
- [ ] Todos los archivos compilados sin errores

### Despliegue de Mocks:
- [ ] MockWETH desplegado
  - Dirección guardada: `_________________`
- [ ] MockAToken desplegado
  - Dirección guardada: `_________________`
- [ ] MockAavePool desplegado
  - Dirección guardada: `_________________`
- [ ] **`inicializar()` llamado en MockAavePool** ✅
  - Transacción exitosa: `status: 0x1`

### Despliegue Principal:
- [ ] GruposAhorroERC7913 desplegado
  - Direcciones correctas en constructor
  - `usarAave` configurado como `true`
  - Dirección guardada: `_________________`

### Crear Grupo:
- [ ] Grupo creado exitosamente
  - `grupoId` obtenido: `_______`
  - Dirección de cuenta multisig obtenida: `_________________`

### Probar Funcionalidad:
- [ ] Aporte realizado exitosamente
  - Fondos depositados
  - Eventos emitidos correctamente
- [ ] Balance total verificado
  - Balance > 0
- [ ] Intereses calculados
  - Intereses >= 0
- [ ] Info del grupo verificada
  - Todos los campos tienen valores correctos
- [ ] Retiro probado (individual o completo)
  - Retiro exitoso o condiciones verificadas

---

## 🎯 Resumen Final para IA

### Sistema Completo:

**Nombre:** Grupos de Ahorro con Aave y Multisig ERC-7913

**Componentes Principales:**
1. `GruposAhorroERC7913`: Factory que crea grupos
2. `CuentaMultisigGrupo`: Cuenta multisig por grupo (una instancia por grupo)
3. `TodosLosMocks`: Mocks para pruebas (MockWETH, MockAToken, MockAavePool)

**Flujo Principal:**
1. Desplegar mocks → MockWETH, MockAToken, MockAavePool
2. **CRÍTICO:** Llamar `inicializar()` en MockAavePool después del deploy
3. Desplegar `GruposAhorroERC7913` con direcciones de mocks
4. Crear grupo con `crearGrupo()` → Crea instancia de `CuentaMultisigGrupo`
5. Aportar con `aportar()` en la cuenta multisig → Depósito automático en Aave
6. Verificar intereses con `calcularIntereses()`
7. Retirar con multisig (requiere firmas múltiples) o individualmente

**Archivos para Remix:**
- `contracts/mocks/TodosLosMocks.sol` (obligatorio)
- `contracts/erc7913/GruposAhorroERC7913.sol` (obligatorio)
- `contracts/interfaces/IAaveInterfaces.sol` (opcional, si se usa import)

**Parámetros Clave:**
- Objetivo en wei (ej: `5000000000000000000` = 5 ETH)
- Fecha objetivo en timestamp (ej: `2000000000`)
- Participantes como array de direcciones
- Signer bytes para configuración multisig (formato depende de SignerERC7913)

**Notas Críticas:**
- SIEMPRE llamar `inicializar()` en MockAavePool después del deploy
- Los aportes se hacen en la cuenta multisig, NO en el contrato principal
- Los intereses en mocks son simulados y crecen lentamente
- En Remix VM, si hay problemas con ERC-7913, usar versión simplificada

**Estado Final:** Sistema completo, organizado, documentado y listo para desplegar.

---

## 📚 Documentación Adicional

Para información más detallada, consultar:
- **`DOCUMENTACION_COMPLETA_IA.md`**: Documentación técnica detallada de cada componente
- **`GUIA_DESPLIEGUE_COMPLETA_IA.md`**: Guía paso a paso detallada de despliegue

---

**Este documento contiene TODO lo necesario para que una IA pueda desplegar y probar el sistema completo.** 🚀

