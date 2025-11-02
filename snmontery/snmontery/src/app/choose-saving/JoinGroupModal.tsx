"use client";
import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { useAccount } from "wagmi";
import { usePrivy } from "@privy-io/react-auth";
import { useInfoGrupo, useAgregarParticipante } from "@/hooks/useGruposAhorro";

export default function JoinGroupModal({ onClose, onDone }: { onClose: () => void, onDone: () => void }) {
  const router = useRouter();
  const { address } = useAccount();
  const { wallet } = usePrivy();
  const { agregarParticipante, isPending, isConfirming, error, receipt } = useAgregarParticipante();
  
  const [grupoId, setGrupoId] = useState("");
  const [errorMessage, setErrorMessage] = useState<string>("");
  const [participanteAddress, setParticipanteAddress] = useState("");
  const [grupoIdForInfo, setGrupoIdForInfo] = useState<bigint | undefined>(undefined);

  // Obtener información del grupo para verificar si el usuario es el creador
  const { grupo } = useInfoGrupo(grupoIdForInfo);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");

    if (!grupoId || grupoId.trim() === "") {
      setErrorMessage("Por favor ingresa el ID del grupo");
      return;
    }

    const grupoIdNumber = parseInt(grupoId);
    if (isNaN(grupoIdNumber) || grupoIdNumber < 0) {
      setErrorMessage("El ID del grupo debe ser un número válido");
      return;
    }

    const walletAddress = wallet?.address || address;
    if (!walletAddress) {
      setErrorMessage("Por favor conecta tu wallet");
      return;
    }

    // Determinar la dirección del participante (la ingresada o la wallet actual)
    const addressToAdd = participanteAddress.trim() || walletAddress;

    // Validar dirección
    if (!addressToAdd.startsWith('0x') || addressToAdd.length !== 42) {
      setErrorMessage("Dirección inválida. Debe ser una dirección Ethereum válida (0x... con 42 caracteres)");
      return;
    }

    // Verificar que el usuario es el creador del grupo
    if (!grupo || grupo.creador.toLowerCase() !== walletAddress.toLowerCase()) {
      setErrorMessage("Solo el creador del grupo puede agregar participantes. Si eres el creador, verifica que estás usando la wallet correcta.");
      return;
    }

    try {
      await agregarParticipante(BigInt(grupoIdNumber), addressToAdd);
    } catch (err: any) {
      console.error('Error al agregar participante:', err);
      const errorMsg = err?.message || err?.toString() || "Error al agregar participante";
      setErrorMessage(errorMsg);
    }
  };

  const handleGrupoIdChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setGrupoId(value);
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 0) {
      setGrupoIdForInfo(BigInt(numValue));
    } else {
      setGrupoIdForInfo(undefined);
    }
  };

  React.useEffect(() => {
    if (receipt?.status === 'success') {
      setParticipanteAddress("");
      setGrupoId("");
      setGrupoIdForInfo(undefined);
      onDone();
      router.push('/dashboard');
    }
  }, [receipt, onDone, router]);

  return (
    <div className="modal-overlay">
      <div className="modal-content join-group-modal">
        <h3>Unirse a un grupo</h3>
        <form onSubmit={handleSubmit}>
          {errorMessage && (
            <div style={{ color: 'red', padding: '1rem', background: '#fee', borderRadius: '4px', marginBottom: '1rem' }}>
              {errorMessage}
            </div>
          )}
          {error && (
            <div style={{ color: 'red', padding: '1rem', background: '#fee', borderRadius: '4px', marginBottom: '1rem' }}>
              Error: {error?.message || error?.toString() || 'Error desconocido'}
            </div>
          )}
          <label>
            ID del Grupo
            <input 
              type="number" 
              name="grupoId" 
              value={grupoId}
              onChange={handleGrupoIdChange}
              placeholder="0"
              min="0"
              required
            />
            <span className="input-help">Ingresa el ID del grupo (debes ser el creador para agregar participantes)</span>
          </label>
          {grupo && (
            <div style={{ marginBottom: '1rem', padding: '0.75rem', background: '#f0f9ff', borderRadius: '4px', fontSize: '0.875rem' }}>
              <strong>Grupo encontrado:</strong> {grupo.nombre}<br />
              <strong>Creador:</strong> {grupo.creador.slice(0, 10)}...{grupo.creador.slice(-8)}<br />
              {grupo.creador.toLowerCase() === (wallet?.address || address)?.toLowerCase() ? (
                <span style={{ color: '#22c55e' }}>✓ Eres el creador de este grupo</span>
              ) : (
                <span style={{ color: '#ef4444' }}>✗ No eres el creador. Solo el creador puede agregar participantes.</span>
              )}
            </div>
          )}
          <label>
            Dirección del Participante (opcional)
            <input 
              type="text" 
              name="participanteAddress" 
              value={participanteAddress}
              onChange={(e) => setParticipanteAddress(e.target.value)}
              placeholder="0x..." 
            />
            <span className="input-help">Si dejas vacío, se agregará tu wallet actual ({wallet?.address || address || 'N/A'})</span>
          </label>
          <div className="modal-actions">
            <button type="button" onClick={() => router.push('/choose-saving')} className="modal-btn" disabled={isPending || isConfirming}>
              Atrás
            </button>
            <button type="submit" className="modal-btn primary" disabled={isPending || isConfirming}>
              {isPending || isConfirming ? "Uniéndose..." : "Unirse"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
