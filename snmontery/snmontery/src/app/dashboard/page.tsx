"use client";

import { usePrivy } from "@privy-io/react-auth";
import { useState, useRef, useEffect } from "react";
import React from "react";
import { useRouter } from "next/navigation";
import { useAccount } from "wagmi";
import { useGruposUsuario, useCuentaGrupo } from "@/hooks/useGruposAhorro";
import GrupoCard from "@/components/GrupoCard";
import AportarModal from "@/components/AportarModal";
import './dashboard.css';
import MiniCalendar from './MiniCalendar';



type WalletStatusProps = {
  wallet?: { address?: string } | null;
};

function WalletStatus({ wallet }: WalletStatusProps) {
  const [showAddress, setShowAddress] = useState(false);
  const [copied, setCopied] = useState(false);
  const address = wallet?.address || "-";
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Alternar automáticamente cada 3 segundos
  useEffect(() => {
    const interval = setInterval(() => {
      setShowAddress((prev) => !prev);
    }, 8000);
    return () => clearInterval(interval);
  }, []);

  const handleCopy = () => {
    navigator.clipboard.writeText(address);
    setCopied(true);
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    timeoutRef.current = setTimeout(() => setCopied(false), 1200);
  };

  return (
    <div
      className={`wallet-status ${wallet ? "connected" : "disconnected"} wallet-status-animated`}
      style={{ cursor: "pointer", minWidth: 220, position: "relative" }}
      title={showAddress ? "Ver estado" : "Ver dirección"}
    >
      <span className="dot"></span>
      <svg width="20" height="20" fill="none" viewBox="0 0 24 24" className="inline mr-1 align-middle"><path d="M17 9V7a5 5 0 00-10 0v2" stroke="#0a1e5e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/><rect x="5" y="9" width="14" height="10" rx="2" stroke="#0a1e5e" strokeWidth="2"/><circle cx="12" cy="14" r="2.5" fill="#ffd700"/></svg>
      <span className="wallet-status-content" style={{ transition: 'opacity 0.3s' }}>
        {showAddress ? (
          <span className="wallet-address">
            {address !== "-" ? (
              <>
                <span className="mono">{address.slice(0, 8)}...{address.slice(-4)}</span>
                <button
                  className="copy-btn"
                  onClick={e => { e.stopPropagation(); handleCopy(); }}
                  title="Copiar dirección"
                  style={{ marginLeft: 8 }}
                >
                  {copied ? (
                    <svg width="18" height="18" fill="none" viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" stroke="#0a1e5e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  ) : (
                    <svg width="18" height="18" fill="none" viewBox="0 0 24 24"><rect x="9" y="9" width="13" height="13" rx="2" stroke="#0a1e5e" strokeWidth="2"/><rect x="3" y="3" width="13" height="13" rx="2" stroke="#0a1e5e" strokeWidth="2"/></svg>
                  )}
                </button>
              </>
            ) : (
              <span className="mono">-</span>
            )}
          </span>
        ) : (
          <span className="wallet-state-label">Wallet: {wallet ? "Conectada" : "Desconectada"}</span>
        )}
      </span>
    </div>
  );
}

export default function DashboardPage() {
  const { user, logout, authenticated, ready } = usePrivy();
  const { address } = useAccount();
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [aportarModal, setAportarModal] = useState<{ grupoId: bigint } | null>(null);
  const router = useRouter();
  const { grupoIds, isLoading: isLoadingGrupos } = useGruposUsuario();

  // Escuchar evento para abrir modal de aportar
  React.useEffect(() => {
    const handleAbrirAportar = (event: any) => {
      setAportarModal({
        grupoId: event.detail.grupoId,
      });
    };

    window.addEventListener('abrirAportarModal', handleAbrirAportar);
    return () => window.removeEventListener('abrirAportarModal', handleAbrirAportar);
  }, []);

  // Redirigir a login tras cerrar sesión
  const handleLogout = async () => {
    await logout();
    router.push("/login");
  };

  if (!ready) return <div className="p-8 text-center">Cargando...</div>;
  if (!authenticated || !user) return <div className="p-8 text-center">No autenticado</div>;

  return (
    <div className="dashboard-bg min-h-screen w-full flex flex-col">
      {/* Top Bar */}
      <div className="dashboard-topbar px-8 py-4">
        {/* Wallet Status */}
        <div className="dashboard-wallet flex items-center gap-3">
          <WalletStatus wallet={user.wallet} />
        </div>
        {/* Logo centrado */}
        <div className="dashboard-logo">
          <img src="/Logo.png" alt="Logo" className="header-logo" />
        </div>
        {/* User Menu */}
        <div className="dashboard-user relative">
          <button
            className="user-btn"
            onClick={() => setUserMenuOpen((v) => !v)}
          >
            <img
              src={`https://api.dicebear.com/7.x/thumbs/svg?seed=${encodeURIComponent(user.email?.address || user.wallet?.address || "user")}`}
              alt="avatar"
              className="user-avatar"
              width={32}
              height={32}
            />
            <span className="user-label">{user.email?.address || user.wallet?.address?.slice(0, 8) + "..."}</span>
            <svg width="18" height="18" fill="none" viewBox="0 0 24 24"><path d="M7 10l5 5 5-5" stroke="#333" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </button>
          {userMenuOpen && (
            <div className="user-menu animate-fadein">
              <button className="user-menu-item" onClick={() => router.push('/choose-saving')}>Volver a "¿Cómo prefieres ahorrar?"</button>
              <button className="user-menu-item">Configuración</button>
              <button className="user-menu-item" onClick={handleLogout}>Cerrar sesión</button>
            </div>
          )}
        </div>
      </div>
      {/* Calendario reducido arriba */}
      <div className="dashboard-calendar-box w-full flex justify-center items-center mt-2 mb-6">
        <MiniCalendar />
      </div>
      {/* Main Content */}
      <div className="dashboard-main flex-1 flex flex-col items-center justify-center gap-8 p-8">
        <div className="dashboard-content flex flex-col gap-8 w-full max-w-7xl">
          {/* Grupos del Usuario */}
          <div className="dashboard-card">
            <h2 className="dashboard-card-title flex items-center gap-2">
              <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
                <path d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m9-5a4 4 0 11-8 0 4 4 0 018 0zm6 2a2 2 0 11-4 0 2 2 0 014 0zm-16 2a2 2 0 11-4 0 2 2 0 014 0z" stroke="#0a1e5e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              Mis Grupos
            </h2>
            <div className="dashboard-card-body">
              {isLoadingGrupos ? (
                <div>Cargando grupos...</div>
              ) : grupoIds.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: '#666' }}>
                  <p>No tienes grupos aún.</p>
                  <button 
                    className="modal-btn primary" 
                    onClick={() => router.push('/choose-saving/crear-grupo')}
                    style={{ marginTop: '1rem' }}
                  >
                    Crear tu Primer Grupo
                  </button>
          </div>
              ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem', marginTop: '1rem' }}>
                  {(grupoIds as bigint[]).map((grupoId) => (
                    <GrupoListItem key={Number(grupoId)} grupoId={grupoId} />
                  ))}
            </div>
              )}
            </div>
          </div>

          {/* Acciones Rápidas */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.5rem' }}>
            <div className="dashboard-card">
              <h2 className="dashboard-card-title flex items-center gap-2">
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
                  <path d="M12 5v14m7-7H5" stroke="#0a1e5e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                Crear un Grupo
              </h2>
              <div className="dashboard-card-body">
                <p style={{ marginBottom: '1rem', color: '#666' }}>
                  Crea un nuevo grupo de ahorro y invita a tus amigos.
                </p>
                <button 
                  className="modal-btn primary" 
                  onClick={() => router.push('/choose-saving/crear-grupo')}
                >
                  Crear Grupo
                </button>
              </div>
            </div>
            <div className="dashboard-card">
              <h2 className="dashboard-card-title flex items-center gap-2">
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24">
                  <path d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m9-5a4 4 0 11-8 0 4 4 0 018 0zm6 2a2 2 0 11-4 0 2 2 0 014 0zm-16 2a2 2 0 11-4 0 2 2 0 014 0z" stroke="#0a1e5e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
                Unirse a un Grupo
              </h2>
              <div className="dashboard-card-body">
                <p style={{ marginBottom: '1rem', color: '#666' }}>
                  Únete a un grupo existente con un código de acceso.
                </p>
                <button 
                  className="modal-btn primary" 
                  onClick={() => router.push('/choose-saving/unirse')}
                >
                  Unirse a Grupo
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Modal para Aportar */}
      {aportarModal && (
        <AportarModal
          grupoId={aportarModal.grupoId}
          onClose={() => setAportarModal(null)}
          onSuccess={() => {
            // Refrescar datos del grupo
            setAportarModal(null);
          }}
        />
      )}
    </div>
  );
}

// Componente helper para mostrar cada grupo
function GrupoListItem({ grupoId }: { grupoId: bigint }) {
  return <GrupoCard grupoId={grupoId} />;
}

