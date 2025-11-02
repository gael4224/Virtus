// Configuración del contrato GruposAhorroConAaveMultisig (versión simplificada)
// TODO: Reemplazar con la dirección real después de desplegar

import { arbitrumSepolia } from 'wagmi/chains';

// Dirección del contrato desplegado
export const CONTRATO_GRUPOS_AHORRO_ADDRESS = 
  process.env.NEXT_PUBLIC_CONTRATO_ADDRESS || 
  '0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec' as `0x${string}`;

// Dirección de los contratos Mock (solo para pruebas locales)
export const MOCK_AAVE_POOL_ADDRESS = 
  process.env.NEXT_PUBLIC_MOCK_AAVE_POOL || 
  '0x0000000000000000000000000000000000000000' as `0x${string}`;

export const MOCK_WETH_ADDRESS = 
  process.env.NEXT_PUBLIC_MOCK_WETH || 
  '0x0000000000000000000000000000000000000000' as `0x${string}`;

export const MOCK_ATOKEN_ADDRESS = 
  process.env.NEXT_PUBLIC_MOCK_ATOKEN || 
  '0x0000000000000000000000000000000000000000' as `0x${string}`;

// Chain ID
export const CHAIN_ID = arbitrumSepolia.id;

// ABI del contrato GruposAhorroConAaveMultisig (versión simplificada)
export const GRUPOS_AHORRO_ABI = [
  // Eventos (formato objeto para Wagmi v2)
  {
    type: 'event',
    name: 'GrupoCreado',
    inputs: [
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'creador', type: 'address', indexed: true },
      { name: 'nombre', type: 'string', indexed: false },
      { name: 'objetivo', type: 'uint256', indexed: false },
      { name: 'fechaObjetivo', type: 'uint256', indexed: false },
      { name: 'quorum', type: 'uint256', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'AporteRealizado',
    inputs: [
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'participante', type: 'address', indexed: true },
      { name: 'cantidad', type: 'uint256', indexed: false },
      { name: 'totalRecaudado', type: 'uint256', indexed: false },
      { name: 'totalEnAave', type: 'uint256', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'MetaAlcanzada',
    inputs: [
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'totalRecaudado', type: 'uint256', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'SolicitudRetiroCreada',
    inputs: [
      { name: 'solicitudId', type: 'uint256', indexed: true },
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'solicitante', type: 'address', indexed: true },
      { name: 'destinatario', type: 'address', indexed: false },
      { name: 'cantidad', type: 'uint256', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'AprobacionAgregada',
    inputs: [
      { name: 'solicitudId', type: 'uint256', indexed: true },
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'aprobador', type: 'address', indexed: true },
      { name: 'numAprobaciones', type: 'uint256', indexed: false },
      { name: 'quorum', type: 'uint256', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'RetiroEjecutado',
    inputs: [
      { name: 'solicitudId', type: 'uint256', indexed: true },
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'destinatario', type: 'address', indexed: true },
      { name: 'cantidad', type: 'uint256', indexed: false },
      { name: 'interesesGenerados', type: 'uint256', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'ParticipanteAgregado',
    inputs: [
      { name: 'grupoId', type: 'uint256', indexed: true },
      { name: 'participante', type: 'address', indexed: true },
    ],
  },
  
  // Funciones principales
  {
    name: 'crearGrupo',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: '_nombre', type: 'string' },
      { name: '_objetivo', type: 'uint256' },
      { name: '_fechaObjetivo', type: 'uint256' },
      { name: '_descripcion', type: 'string' },
      { name: '_quorum', type: 'uint256' },
      { name: '_aprobadores', type: 'address[]' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'aportar',
    type: 'function',
    stateMutability: 'payable',
    inputs: [{ name: '_grupoId', type: 'uint256' }],
    outputs: [],
  },
  {
    name: 'obtenerGrupo',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: '_grupoId', type: 'uint256' }],
    outputs: [
      { name: 'id', type: 'uint256' },
      { name: 'creador', type: 'address' },
      { name: 'nombre', type: 'string' },
      { name: 'objetivo', type: 'uint256' },
      { name: 'totalRecaudado', type: 'uint256' },
      { name: 'totalEnAave', type: 'uint256' },
      { name: 'fechaObjetivo', type: 'uint256' },
      { name: 'descripcion', type: 'string' },
      { name: 'activo', type: 'bool' },
      { name: 'metaAlcanzada', type: 'bool' },
      { name: 'quorum', type: 'uint256' },
    ],
  },
  {
    name: 'obtenerParticipantes',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: '_grupoId', type: 'uint256' }],
    outputs: [{ name: '', type: 'address[]' }],
  },
  {
    name: 'obtenerAporte',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: '_grupoId', type: 'uint256' },
      { name: '_participante', type: 'address' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'obtenerBalanceTotal',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: '_grupoId', type: 'uint256' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'obtenerGruposPorUsuario',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: '_usuario', type: 'address' }],
    outputs: [{ name: '', type: 'uint256[]' }],
  },
  {
    name: 'totalGrupos',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'solicitarRetiro',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: '_grupoId', type: 'uint256' },
      { name: '_destinatario', type: 'address' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'aprobarRetiro',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: '_grupoId', type: 'uint256' },
      { name: '_solicitudId', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    name: 'ejecutarRetiro',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: '_grupoId', type: 'uint256' },
      { name: '_solicitudId', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    name: 'agregarParticipante',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: '_grupoId', type: 'uint256' },
      { name: '_participante', type: 'address' },
    ],
    outputs: [],
  },
] as const;

// ABI del contrato CuentaMultisigGrupo (DEPRECADO - ya no se usa)
// Mantenido por compatibilidad, pero no se usa con la versión simplificada
export const CUENTA_MULTISIG_ABI = [
  // Esta ABI ya no se usa con GruposAhorroConAaveMultisig
  // Los grupos no tienen cuenta multisig separada
] as const;

