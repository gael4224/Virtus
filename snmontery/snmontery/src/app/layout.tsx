"use client";
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { PrivyProvider } from "@privy-io/react-auth";
import { WagmiProvider } from '@privy-io/wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { wagmiConfig } from '@/lib/wagmi-config';

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const queryClient = new QueryClient();

// Definir supportedChains fuera del componente para evitar recrearlo
const supportedChains = [wagmiConfig.chains[0]];

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // En desarrollo, deshabilitar embedded wallets si no hay HTTPS
  // Esto permite que funcione en HTTP local y desde IP local
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  // Configuración de Privy: deshabilitar embedded wallets en desarrollo HTTP
  // Los usuarios pueden usar MetaMask, Phantom u otros wallets externos
  const privyConfig: any = {
    appearance: {
      theme: "light",
    },
    supportedChains,
    loginMethods: ['email', 'wallet'], // Permitir email y wallet externas (MetaMask, Phantom)
  };

  // Solo habilitar embedded wallets si NO estamos en desarrollo
  // En producción con HTTPS, las embedded wallets funcionarán
  if (!isDevelopment) {
    privyConfig.embeddedWallets = {
      createOnLogin: "all-users" as const,
    };
  }

  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        <PrivyProvider
          appId={process.env.NEXT_PUBLIC_PRIVY_APP_ID || "cmhfxhj1p01spl90cv8voyekm"}
          config={privyConfig}
        >
          <QueryClientProvider client={queryClient}>
            <WagmiProvider config={wagmiConfig}>
          {children}
            </WagmiProvider>
          </QueryClientProvider>
        </PrivyProvider>
      </body>
    </html>
  );
}
