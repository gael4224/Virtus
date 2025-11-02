"use client";

import React, { useState } from 'react';
import { useAportarGrupo, useBalanceGrupo } from '@/hooks/useGruposAhorro';
import { formatEther } from 'viem';

interface AportarModalProps {
  grupoId: bigint;
  onClose: () => void;
  onSuccess?: () => void;
}

export default function AportarModal({ grupoId, onClose, onSuccess }: AportarModalProps) {
  const [cantidad, setCantidad] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const { aportar, isPending, isConfirming, error, receipt } = useAportarGrupo();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');

    if (!cantidad || parseFloat(cantidad) <= 0) {
      setErrorMessage('Por favor ingresa una cantidad válida');
      return;
    }

    try {
      await aportar(grupoId, cantidad);
    } catch (err: any) {
      setErrorMessage(err?.message || 'Error al aportar fondos');
    }
  };

  // Si la transacción se confirmó, ejecutar onSuccess
  React.useEffect(() => {
    if (receipt?.status === 'success') {
      onSuccess?.();
      onClose();
    }
  }, [receipt, onSuccess, onClose]);

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <h3>Aportar Fondos al Grupo #{Number(grupoId)}</h3>
        
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

        <form onSubmit={handleSubmit}>
          <label>
            Cantidad a Aportar (ETH)
            <input
              type="number"
              step="0.0001"
              min="0"
              value={cantidad}
              onChange={(e) => setCantidad(e.target.value)}
              placeholder="0.01"
              required
            />
            <span className="input-help">Ingresa la cantidad en ETH (ej: 0.01)</span>
          </label>

          <div className="modal-actions">
            <button type="button" onClick={onClose} className="modal-btn" disabled={isPending || isConfirming}>
              Cancelar
            </button>
            <button type="submit" className="modal-btn primary" disabled={isPending || isConfirming}>
              {isPending || isConfirming ? 'Procesando...' : 'Aportar Fondos'}
            </button>
          </div>
        </form>

        {(isPending || isConfirming) && (
          <div style={{ marginTop: '1rem', padding: '1rem', background: '#f0f9ff', borderRadius: '4px' }}>
            <p>⏳ Transacción en proceso...</p>
            <p style={{ fontSize: '0.875rem', color: '#666' }}>
              {isPending ? 'Esperando confirmación...' : 'Confirmando transacción...'}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

