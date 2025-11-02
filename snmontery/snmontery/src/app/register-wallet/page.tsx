"use client";

import { usePrivy } from "@privy-io/react-auth";
import { useEffect } from "react";

export default function RegisterWalletPage() {
  const { ready, authenticated, user, login, logout } = usePrivy();

  useEffect(() => {
    if (ready && authenticated && user) {
      // Aquí podrías hacer lógica adicional, como guardar la wallet en tu backend
    }
  }, [ready, authenticated, user]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-zinc-50 dark:bg-black">
      <div className="bg-white dark:bg-zinc-900 rounded-lg shadow-lg p-8 w-full max-w-md">
        <h1 className="text-2xl font-bold mb-4 text-center">Registrar Wallet</h1>
        {!authenticated ? (
          <button
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            onClick={() => login()}
          >
            Iniciar sesión con Privy
          </button>
        ) : (
          <div className="flex flex-col items-center gap-4">
            <p className="text-green-600 font-semibold">¡Sesión iniciada!</p>
            <p className="text-sm text-zinc-700 dark:text-zinc-300 break-all">
              <span className="font-mono">Wallet: </span>
              {user?.wallet?.address || "No wallet address"}
            </p>
            <button
              className="mt-4 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
              onClick={logout}
            >
              Cerrar sesión
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
