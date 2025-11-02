"use client";

import { useWriteContract, useReadContract, useWaitForTransactionReceipt, useAccount, useChainId } from 'wagmi';
import { usePrivy } from '@privy-io/react-auth';
import { parseEther, formatEther } from 'viem';
import { GRUPOS_AHORRO_ABI, CONTRATO_GRUPOS_AHORRO_ADDRESS, CHAIN_ID } from '@/lib/contract-config';

// Tipos para los grupos
export interface GrupoInfo {
  id: bigint;
  creador: string;
  nombre: string;
  objetivo: bigint;
  totalRecaudado: bigint;
  totalEnAave: bigint;
  fechaObjetivo: bigint;
  descripcion: string;
  activo: boolean;
  metaAlcanzada: boolean;
  quorum: bigint;
  participantes: string[];
}

export interface CrearGrupoParams {
  nombre: string;
  objetivo: string; // En ETH, se convertirá a wei
  fechaObjetivo: Date;
  descripcion: string;
  participantes: string[]; // Array de direcciones (incluye al creador automáticamente)
}

/**
 * Hook para crear un nuevo grupo
 */
export function useCrearGrupo() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { data: receipt, isLoading: isConfirming } = useWaitForTransactionReceipt({
    hash,
  });
  const { user } = usePrivy();
  const { address } = useAccount(); // Obtener dirección de wagmi (funciona con Privy y MetaMask)
  const wallet = user?.wallet;
  const chainId = useChainId();

  const crearGrupo = async (params: CrearGrupoParams) => {
    // Usar address de useAccount como fallback si wallet de Privy no está disponible
    const walletAddress = wallet?.address || address;
    
    if (!walletAddress) {
      throw new Error('Wallet no conectada. Por favor conecta tu wallet en MetaMask o Privy.');
    }

    if (chainId !== CHAIN_ID) {
      throw new Error(`Por favor cambia a Arbitrum Sepolia (Chain ID: ${CHAIN_ID})`);
    }

    // Convertir fecha a timestamp
    const fechaTimestamp = BigInt(Math.floor(params.fechaObjetivo.getTime() / 1000));
    
    // Convertir objetivo de ETH a wei
    const objetivoWei = parseEther(params.objetivo);

    // Preparar participantes (eliminar duplicados y el creador)
    const participantesUnicos = [...new Set(params.participantes)]
      .map(p => p.trim())
      .filter(p => p.length > 0 && p.toLowerCase() !== walletAddress.toLowerCase())
      .filter(p => p.startsWith('0x') && p.length === 42) as `0x${string}`[]; // Validar que sean direcciones válidas
    
    // Aprobadores = todos los participantes (incluyendo al creador)
    // El contrato requiere al menos un aprobador
    const aprobadores = [walletAddress as `0x${string}`, ...participantesUnicos];
    
    // Validar que haya al menos un aprobador (siempre hay al menos el creador)
    if (aprobadores.length === 0) {
      throw new Error('Debe haber al menos un aprobador (el creador)');
    }
    
    // Quorum = mayoría (mínimo 1, máximo número de aprobadores)
    const quorum = aprobadores.length === 1 
      ? BigInt(1) 
      : BigInt(Math.ceil(aprobadores.length / 2)); // Mayoría simple
    
    // Validar que quorum no sea mayor que el número de aprobadores
    if (quorum > BigInt(aprobadores.length)) {
      throw new Error('El quorum no puede ser mayor al número de aprobadores');
    }

    writeContract({
      address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
      abi: GRUPOS_AHORRO_ABI,
      functionName: 'crearGrupo',
      args: [
        params.nombre,
        objetivoWei,
        fechaTimestamp,
        params.descripcion,
        quorum,
        aprobadores,
      ],
    });
  };

  return {
    crearGrupo,
    hash,
    isPending,
    isConfirming,
    receipt,
    error,
  };
}

/**
 * Hook para obtener grupos de un usuario
 */
export function useGruposUsuario() {
  const { address } = useAccount();

  const { data: grupoIds, isLoading, error } = useReadContract({
    address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
    abi: GRUPOS_AHORRO_ABI,
    functionName: 'obtenerGruposPorUsuario',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  return {
    grupoIds: grupoIds || [],
    isLoading,
    error,
  };
}

/**
 * Hook para obtener información de un grupo
 */
export function useInfoGrupo(grupoId: bigint | undefined) {
  const { data: infoGrupo, isLoading: isLoadingGrupo, error: errorGrupo } = useReadContract({
    address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
    abi: GRUPOS_AHORRO_ABI,
    functionName: 'obtenerGrupo',
    args: grupoId !== undefined ? [grupoId] : undefined,
    query: {
      enabled: grupoId !== undefined,
    },
  });

  const { data: participantes, isLoading: isLoadingParticipantes, error: errorParticipantes } = useReadContract({
    address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
    abi: GRUPOS_AHORRO_ABI,
    functionName: 'obtenerParticipantes',
    args: grupoId !== undefined ? [grupoId] : undefined,
    query: {
      enabled: grupoId !== undefined,
    },
  });

  const isLoading = isLoadingGrupo || isLoadingParticipantes;
  const error = errorGrupo || errorParticipantes;

  if (!infoGrupo || !participantes) {
    return {
      grupo: null,
      isLoading,
      error,
    };
  }

  const grupo: GrupoInfo = {
    id: infoGrupo[0],
    creador: infoGrupo[1],
    nombre: infoGrupo[2],
    objetivo: infoGrupo[3],
    totalRecaudado: infoGrupo[4],
    totalEnAave: infoGrupo[5],
    fechaObjetivo: infoGrupo[6],
    descripcion: infoGrupo[7],
    activo: infoGrupo[8],
    metaAlcanzada: infoGrupo[9],
    quorum: infoGrupo[10],
    participantes: participantes as string[],
  };

  return {
    grupo,
    isLoading,
    error,
  };
}

/**
 * Hook para aportar fondos a un grupo
 */
export function useAportarGrupo() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { data: receipt, isLoading: isConfirming } = useWaitForTransactionReceipt({
    hash,
  });
  const chainId = useChainId();

  const aportar = async (grupoId: bigint, cantidadETH: string) => {
    if (chainId !== CHAIN_ID) {
      throw new Error(`Por favor cambia a Arbitrum Sepolia (Chain ID: ${CHAIN_ID})`);
    }

    const cantidadWei = parseEther(cantidadETH);

    writeContract({
      address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
      abi: GRUPOS_AHORRO_ABI,
      functionName: 'aportar',
      args: [grupoId],
      value: cantidadWei,
    });
  };

  return {
    aportar,
    hash,
    isPending,
    isConfirming,
    receipt,
    error,
  };
}

/**
 * Hook para obtener balance total de un grupo
 */
export function useBalanceGrupo(grupoId: bigint | undefined) {
  const { data: balance, isLoading, error } = useReadContract({
    address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
    abi: GRUPOS_AHORRO_ABI,
    functionName: 'obtenerBalanceTotal',
    args: grupoId !== undefined ? [grupoId] : undefined,
    query: {
      enabled: grupoId !== undefined,
    },
  });

  return {
    balance: balance ? formatEther(balance as bigint) : '0',
    balanceWei: balance as bigint | undefined,
    isLoading,
    error,
  };
}

/**
 * Hook para obtener intereses generados
 * Calcula la diferencia entre el balance total y el total recaudado
 */
export function useInteresesGrupo(grupoId: bigint | undefined) {
  const { grupo, isLoading: isLoadingGrupo } = useInfoGrupo(grupoId);
  const { balanceWei, isLoading: isLoadingBalance } = useBalanceGrupo(grupoId);

  const isLoading = isLoadingGrupo || isLoadingBalance;

  if (!grupo || !balanceWei) {
    return {
      intereses: '0',
      interesesWei: BigInt(0),
      isLoading,
      error: null,
    };
  }

  // Intereses = Balance Total - Total Recaudado
  const interesesWei = balanceWei > grupo.totalRecaudado 
    ? balanceWei - grupo.totalRecaudado 
    : BigInt(0);

  return {
    intereses: formatEther(interesesWei),
    interesesWei,
    isLoading,
    error: null,
  };
}

/**
 * Hook para obtener aporte de un participante
 */
export function useAporteParticipante(grupoId: bigint | undefined, participante?: string) {
  const { data: aporte, isLoading, error } = useReadContract({
    address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
    abi: GRUPOS_AHORRO_ABI,
    functionName: 'obtenerAporte',
    args: grupoId !== undefined && participante ? [grupoId, participante as `0x${string}`] : undefined,
    query: {
      enabled: grupoId !== undefined && !!participante,
    },
  });

  return {
    aporte: aporte ? formatEther(aporte as bigint) : '0',
    aporteWei: aporte as bigint | undefined,
    isLoading,
    error,
  };
}

/**
 * Hook para agregar un participante a un grupo existente
 */
export function useAgregarParticipante() {
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { data: receipt, isLoading: isConfirming } = useWaitForTransactionReceipt({
    hash,
  });
  const chainId = useChainId();

  const agregarParticipante = async (grupoId: bigint, participante: string) => {
    if (chainId !== CHAIN_ID) {
      throw new Error(`Por favor cambia a Arbitrum Sepolia (Chain ID: ${CHAIN_ID})`);
    }

    if (!participante.startsWith('0x') || participante.length !== 42) {
      throw new Error('Dirección inválida. Debe ser una dirección Ethereum válida (0x... con 42 caracteres)');
    }

    writeContract({
      address: CONTRATO_GRUPOS_AHORRO_ADDRESS as `0x${string}`,
      abi: GRUPOS_AHORRO_ABI,
      functionName: 'agregarParticipante',
      args: [grupoId, participante as `0x${string}`],
    });
  };

  return {
    agregarParticipante,
    hash,
    isPending,
    isConfirming,
    receipt,
    error,
  };
}

// Hook deprecated - mantenido por compatibilidad pero no se usa
export function useCuentaGrupo(_grupoId: bigint | undefined) {
  // Ya no existe cuenta multisig separada
  return {
    cuenta: undefined,
    isLoading: false,
    error: null,
  };
}
