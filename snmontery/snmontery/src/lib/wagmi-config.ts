import { createConfig } from '@privy-io/wagmi';
import { http } from 'wagmi';
import { arbitrumSepolia } from 'wagmi/chains';

// Configurar cadenas soportadas
const chains = [arbitrumSepolia] as const;

// Configurar RPC endpoints
const transports = {
  [arbitrumSepolia.id]: http(
    process.env.NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL || 
    'https://sepolia-rollup.arbitrum.io/rpc'
  ),
};

// Crear configuración de Wagmi usando el createConfig de @privy-io/wagmi
// Esto asegura la integración correcta con Privy
export const wagmiConfig = createConfig({
  chains,
  transports,
});

