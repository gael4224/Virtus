# Integración de Smart Contracts con el Frontend

## Resumen

Se ha integrado el smart contract `GruposAhorroERC7913` con el frontend en `snmontery/snmontery/`.

## Archivos Creados/Modificados

### 1. Configuración Base

- **`lib/wagmi-config.ts`**: Configuración de Wagmi + Privy para Arbitrum Sepolia
- **`lib/contract-config.ts`**: Configuración del contrato (ABI, direcciones)
- **`src/app/layout.tsx`**: Actualizado para incluir WagmiProvider y QueryClientProvider

### 2. Hooks Personalizados

- **`src/hooks/useGruposAhorro.ts`**: Hooks para interactuar con los smart contracts
  - `useCrearGrupo()`: Crear un nuevo grupo
  - `useGruposUsuario()`: Obtener grupos del usuario
  - `useInfoGrupo()`: Obtener información de un grupo
  - `useCuentaGrupo()`: Obtener dirección de cuenta multisig
  - `useAportarGrupo()`: Aportar fondos a un grupo
  - `useBalanceGrupo()`: Obtener balance total
  - `useInteresesGrupo()`: Obtener intereses generados
  - `useAporteParticipante()`: Obtener aporte de un participante

### 3. Componentes

- **`src/components/GrupoCard.tsx`**: Tarjeta para mostrar información de un grupo
- **`src/app/choose-saving/GroupFormModal.tsx`**: Actualizado para conectar con `crearGrupo()`
- **`src/app/dashboard/page.tsx`**: Actualizado para mostrar grupos del usuario

### 4. Dependencias

Actualizado `package.json` con:
- `@privy-io/wagmi`: ^1.0.0
- `@tanstack/react-query`: ^5.0.0
- `viem`: ^2.0.0
- `wagmi`: ^2.0.0

## Configuración Necesaria

### Variables de Entorno

Crear archivo `.env.local` con:

```env
NEXT_PUBLIC_PRIVY_APP_ID=tu_app_id_de_privy
NEXT_PUBLIC_CONTRATO_ADDRESS=0x...  # Dirección del contrato desplegado
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
```

### Dirección del Contrato

Después de desplegar el contrato en Arbitrum Sepolia, actualizar en `lib/contract-config.ts`:

```typescript
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = '0x...' as `0x${string}`;
```

## Funcionalidades Implementadas

### ✅ Crear Grupo

- Formulario en `GroupFormModal.tsx` conectado con `crearGrupo()`
- Validación de campos
- Conversión de valores a wei
- Redirección al dashboard después de crear

### ✅ Ver Grupos

- Dashboard muestra todos los grupos del usuario
- Cada grupo muestra:
  - Objetivo y progreso
  - Balance total e intereses
  - Aporte del usuario
  - Estado (activo/inactivo/meta alcanzada)
  - Participantes

### ⏳ Pendiente

- **Aportar Fondos**: Botón está preparado, falta modal de confirmación
- **Retirar Fondos**: Requiere implementación de multisig
- **Unirse a Grupo**: Falta implementar sistema de códigos de acceso

## Próximos Pasos

1. **Desplegar contrato en Arbitrum Sepolia**
2. **Actualizar dirección en `contract-config.ts`**
3. **Implementar modal para aportar fondos**
4. **Implementar retiro con multisig**
5. **Sistema de códigos de acceso para unirse a grupos**
6. **Testing completo en testnet**

## Notas Importantes

- El contrato debe estar desplegado antes de usar el frontend
- Asegurar que la wallet está conectada a Arbitrum Sepolia
- Los valores en el formulario deben ser en ETH (se convierten automáticamente a wei)
- Los participantes deben ser direcciones válidas de Ethereum

