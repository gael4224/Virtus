"use client";

import React from 'react';
import { useInfoGrupo, useBalanceGrupo, useInteresesGrupo, useAporteParticipante, GrupoInfo } from '@/hooks/useGruposAhorro';
import { useAccount } from 'wagmi';
import { formatEther } from 'viem';

interface GrupoCardProps {
  grupoId: bigint;
}

export default function GrupoCard({ grupoId }: GrupoCardProps) {
  const { address } = useAccount();
  const { grupo, isLoading: isLoadingInfo } = useInfoGrupo(grupoId);
  const { balance, isLoading: isLoadingBalance } = useBalanceGrupo(grupoId);
  const { intereses, isLoading: isLoadingIntereses } = useInteresesGrupo(grupoId);
  const { aporte, isLoading: isLoadingAporte } = useAporteParticipante(grupoId, address);

  if (isLoadingInfo || !grupo) {
    return (
      <div className="dashboard-card">
        <div className="dashboard-card-body">Cargando grupo...</div>
      </div>
    );
  }

  const fechaObjetivo = new Date(Number(grupo.fechaObjetivo) * 1000);
  const porcentajeCompletado = grupo.objetivo > 0n 
    ? (Number(grupo.totalRecaudado) / Number(grupo.objetivo)) * 100 
    : 0;

  return (
    <div className="dashboard-card">
      <div style={{ marginBottom: '1rem' }}>
        <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>
          Grupo #{Number(grupoId)}
        </h3>
        {grupo && (
          <p style={{ color: '#666', fontSize: '0.875rem' }}>
            {grupo.nombre}
          </p>
        )}
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <span>Objetivo:</span>
          <strong>{formatEther(grupo.objetivo)} ETH</strong>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <span>Total Recaudado:</span>
          <strong>{formatEther(grupo.totalRecaudado)} ETH</strong>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <span>Balance Total:</span>
          <strong>{balance} ETH</strong>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <span>Intereses Generados:</span>
          <strong style={{ color: '#22c55e' }}>+{intereses} ETH</strong>
        </div>
        {address && (
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
            <span>Tu Aporte:</span>
            <strong>{aporte} ETH</strong>
          </div>
        )}
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <span>Fecha Objetivo:</span>
          <span>{fechaObjetivo.toLocaleDateString()}</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
          <span>Estado:</span>
          <span style={{ 
            color: grupo.activo ? (grupo.metaAlcanzada ? '#22c55e' : '#f59e0b') : '#ef4444',
            fontWeight: 'bold'
          }}>
            {grupo.metaAlcanzada ? 'Meta Alcanzada ✓' : grupo.activo ? 'Activo' : 'Inactivo'}
          </span>
        </div>
      </div>

      {/* Barra de progreso */}
      <div style={{ marginBottom: '1rem' }}>
        <div style={{ 
          width: '100%', 
          height: '20px', 
          background: '#e5e7eb', 
          borderRadius: '10px',
          overflow: 'hidden'
        }}>
          <div style={{
            width: `${Math.min(porcentajeCompletado, 100)}%`,
            height: '100%',
            background: grupo.metaAlcanzada ? '#22c55e' : '#3b82f6',
            transition: 'width 0.3s ease'
          }} />
        </div>
        <p style={{ textAlign: 'center', fontSize: '0.875rem', marginTop: '0.25rem' }}>
          {porcentajeCompletado.toFixed(1)}% completado
        </p>
      </div>

      <div style={{ marginBottom: '0.5rem' }}>
        <strong>Participantes:</strong>
        <div style={{ marginTop: '0.25rem', fontSize: '0.875rem' }}>
          {grupo.participantes.map((p, i) => (
            <div key={i} style={{ marginBottom: '0.25rem' }}>
              {p.slice(0, 10)}...{p.slice(-8)} {p.toLowerCase() === address?.toLowerCase() && '(Tú)'}
            </div>
          ))}
        </div>
      </div>

      <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
        {grupo.activo && !grupo.metaAlcanzada && (
          <button 
            className="modal-btn primary"
            onClick={() => {
              // El modal se abrirá desde el componente padre
              window.dispatchEvent(new CustomEvent('abrirAportarModal', { 
                detail: { grupoId } 
              }));
            }}
          >
            Aportar Fondos
          </button>
        )}
        {(!grupo.activo || grupo.metaAlcanzada || fechaObjetivo < new Date()) && (
          <button 
            className="modal-btn"
            onClick={() => {
              // TODO: Abrir modal para retirar
              alert('Funcionalidad de retiro próximamente (requiere multisig)');
            }}
          >
            Retirar Fondos
          </button>
        )}
      </div>
    </div>
  );
}

