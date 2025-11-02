"use client";
import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { usePrivy } from "@privy-io/react-auth";
import { useAccount } from "wagmi";
import { useCrearGrupo, useAgregarParticipante } from "@/hooks/useGruposAhorro";
import { decodeEventLog, type Abi } from "viem";
import { GRUPOS_AHORRO_ABI } from "@/lib/contract-config";

export default function GroupFormModal({ onClose, onDone, showOverlay = true }: { onClose: () => void, onDone: () => void, showOverlay?: boolean }) {
  const router = useRouter();
  const { wallet } = usePrivy();
  const { address } = useAccount();
  const { crearGrupo, isPending, isConfirming, error, receipt, hash } = useCrearGrupo();
  const { agregarParticipante, isPending: isAddingParticipant, receipt: receiptAddParticipant } = useAgregarParticipante();
  
  const [purpose, setPurpose] = useState("");
  const [nombre, setNombre] = useState("");
  const [objetivo, setObjetivo] = useState("");
  const [fecha, setFecha] = useState("");
  const [participantes, setParticipantes] = useState("");
  const [otroProposito, setOtroProposito] = useState("");
  const [errorMessage, setErrorMessage] = useState<string>("");
  const [participantesToAdd, setParticipantesToAdd] = useState<string[]>([]);
  const [grupoIdCreated, setGrupoIdCreated] = useState<bigint | null>(null);
  const [currentParticipantIndex, setCurrentParticipantIndex] = useState(0);
  
  const purposes = [
    "Boda",
    "Viaje Familiar",
    "Viaje",
    "Otro",
    "Cumpleaños",
    "Compra de un carro",
  ];
  
  // Simulación de cálculo de plazos, cantidad a ahorrar, rendimiento esperado
  const plazos = objetivo && fecha ? 12 : "";
  const cantidadAhorrar = objetivo && plazos ? (Number(objetivo) / Number(plazos)).toFixed(2) : "";
  const rendimiento = objetivo ? (Number(objetivo) * 0.05).toFixed(2) : "";
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage("");
    
    // Validaciones
    if (!nombre || !objetivo || !fecha) {
      setErrorMessage("Por favor completa todos los campos obligatorios");
      return;
    }
    
    if (!wallet?.address && !address) {
      setErrorMessage("Por favor conecta tu wallet");
      return;
    }
    
    // Convertir direcciones de participantes (separadas por comas)
    // Nota: El creador se agrega automáticamente en el hook, no lo incluimos aquí
    let participantesFinales: string[] = [];
    
    if (participantes.trim().length > 0) {
      const participantesList = participantes
        .split(',')
        .map(p => p.trim())
        .filter(p => p.length > 0);
      
      // Validar que las direcciones sean válidas (si hay participantes)
      if (participantesList.length > 0) {
        const participantesInvalidos = participantesList.filter(
          p => !p.startsWith('0x') || p.length !== 42
        );
        
        if (participantesInvalidos.length > 0) {
          setErrorMessage(`Direcciones inválidas: ${participantesInvalidos.join(', ')}. Deben ser direcciones Ethereum válidas (0x... con 42 caracteres)`);
          return;
        }
        
        // Remover el creador de la lista (si está incluido)
        const direccionCreador = wallet?.address || address;
        participantesFinales = participantesList.filter(
          p => p.toLowerCase() !== direccionCreador?.toLowerCase()
        );
      }
    }
    
    // Convertir fecha a Date
    const fechaObjetivo = new Date(fecha);
    if (isNaN(fechaObjetivo.getTime())) {
      setErrorMessage("Fecha inválida");
      return;
    }
    
    // Descripción usando purpose
    const descripcion = purpose === "Otro" ? otroProposito : purpose || "Grupo de ahorro";
    
    // Guardar participantes para agregarlos después de crear el grupo
    setParticipantesToAdd(participantesFinales);
    setCurrentParticipantIndex(0);
    
    try {
      await crearGrupo({
        nombre,
        objetivo,
        fechaObjetivo,
        descripcion,
        participantes: (participantesFinales || []) as `0x${string}`[],
      });
    } catch (err: any) {
      console.error('Error al crear grupo:', err);
      const errorMessage = err?.message || err?.toString() || "Error al crear el grupo";
      setErrorMessage(errorMessage);
      setParticipantesToAdd([]);
    }
  };
  
  // Extraer grupoId del evento GrupoCreado después de crear el grupo
  React.useEffect(() => {
    if (receipt?.status === 'success' && receipt.logs && grupoIdCreated === null) {
      try {
        // Buscar el evento GrupoCreado en los logs
        for (const log of receipt.logs) {
          try {
            const decoded = decodeEventLog({
              abi: GRUPOS_AHORRO_ABI as Abi,
              data: log.data,
              topics: log.topics,
            });
            
            if (decoded.eventName === 'GrupoCreado') {
              const grupoId = decoded.args.grupoId as bigint;
              setGrupoIdCreated(grupoId);
              break;
            }
          } catch (e) {
            // Continuar con el siguiente log si este no coincide
            continue;
          }
        }
      } catch (err) {
        console.error('Error al decodificar evento:', err);
      }
    }
  }, [receipt, grupoIdCreated]);

  // Agregar participantes después de obtener el grupoId
  React.useEffect(() => {
    if (grupoIdCreated !== null && participantesToAdd.length > 0 && currentParticipantIndex < participantesToAdd.length) {
      const participante = participantesToAdd[currentParticipantIndex];
      if (participante) {
        agregarParticipante(grupoIdCreated, participante).catch((err: any) => {
          console.error(`Error al agregar participante ${participante}:`, err);
          setErrorMessage(`Error al agregar participante ${participante.slice(0, 10)}...`);
        });
      }
    }
  }, [grupoIdCreated, participantesToAdd, currentParticipantIndex, agregarParticipante]);

  // Avanzar al siguiente participante cuando se confirme la transacción de agregar
  React.useEffect(() => {
    if (receiptAddParticipant?.status === 'success') {
      if (currentParticipantIndex < participantesToAdd.length - 1) {
        setCurrentParticipantIndex(currentParticipantIndex + 1);
      } else {
        // Todos los participantes agregados, redirigir al dashboard
        setParticipantesToAdd([]);
        setGrupoIdCreated(null);
        setCurrentParticipantIndex(0);
        onDone();
        router.push('/dashboard');
      }
    }
  }, [receiptAddParticipant, currentParticipantIndex, participantesToAdd.length, onDone, router]);

  // Si no hay participantes que agregar, redirigir inmediatamente
  React.useEffect(() => {
    if (grupoIdCreated !== null && participantesToAdd.length === 0) {
      onDone();
      router.push('/dashboard');
    }
  }, [grupoIdCreated, participantesToAdd.length, onDone, router]);
  
  const content = (
    <div className="modal-content group-form-modal">
        {/* Formulario a la izquierda */}
        <form className="group-form" onSubmit={handleSubmit}>
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
            Nombre de Grupo
            <input type="text" name="nombre" value={nombre} onChange={e => setNombre(e.target.value)} required />
            <span className="input-help">Ejemplo: "Viaje Cancún 2025"</span>
          </label>
          <label>
            Objetivo (Monto total en ETH)
            <input type="number" name="objetivo" value={objetivo} onChange={e => setObjetivo(e.target.value)} step="0.0001" min="0" required />
            <span className="input-help">¿Cuánto quieren ahorrar en total?</span>
          </label>
          <label>
            Fecha del Objetivo
            <input type="date" name="fecha" value={fecha} onChange={e => setFecha(e.target.value)} required />
            <span className="input-help">¿Para cuándo quieren lograrlo?</span>
          </label>
          <label>
            Agregar participantes (direcciones)
            <input type="text" name="participantes" placeholder="0x123..., 0x456..." value={participantes} onChange={e => setParticipantes(e.target.value)} />
            <span className="input-help">Direcciones separadas por coma (opcional)</span>
          </label>
          <fieldset className="purpose-fieldset">
            <legend>Propósito</legend>
            <div className="purpose-radio-list">
              {purposes.map((p) => (
                <label key={p} className="purpose-radio">
                  <input
                    type="radio"
                    name="proposito"
                    value={p}
                    checked={purpose === p}
                    onChange={() => setPurpose(p)}
                  />
                  {p}
                  {p === "Otro" && purpose === "Otro" && (
                    <input
                      type="text"
                      name="otro_proposito"
                      placeholder="Especifica el propósito"
                      className="other-purpose-input"
                      value={otroProposito}
                      onChange={e => setOtroProposito(e.target.value)}
                    />
                  )}
                </label>
              ))}
            </div>
          </fieldset>
          <div className="modal-actions">
            <button type="button" onClick={() => router.push('/choose-saving')} className="modal-btn" disabled={isPending || isConfirming}>
              Atrás
            </button>
                  <button type="submit" className="modal-btn primary" disabled={isPending || isConfirming || isAddingParticipant}>
                    {isPending || isConfirming 
                      ? "Creando grupo..." 
                      : isAddingParticipant 
                        ? `Agregando participantes... (${currentParticipantIndex + 1}/${participantesToAdd.length})`
                        : "Crear Grupo"}
                  </button>
          </div>
        </form>
        {/* Resumen a la derecha */}
        <div className="group-summary">
          <div>
            <label>Total</label>
            <div className="summary-box">{objetivo || "-"}</div>
          </div>
          <div>
            <label>Plazos</label>
            <div className="summary-box">{plazos || "-"}</div>
          </div>
          <div>
            <label>Cantidad a ahorrar</label>
            <div className="summary-box">{cantidadAhorrar || "-"}</div>
          </div>
          <div>
            <label>Rendimiento esperado</label>
            <div className="summary-box">{rendimiento || "-"}</div>
          </div>
          <div>
            <label>Propósito</label>
            <div className="summary-box">{purpose === "Otro" ? otroProposito : purpose || "-"}</div>
          </div>
        </div>
      </div>
    );

  if (showOverlay) {
    return (
      <div className="modal-overlay">
        {content}
      </div>
    );
  }

  return content;
}
