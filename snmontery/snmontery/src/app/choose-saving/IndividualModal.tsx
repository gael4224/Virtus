"use client";
import React, { useState } from "react";
import { useRouter } from "next/navigation";

export default function IndividualModal({ onClose, onDone }: { onClose: () => void, onDone: () => void }) {
  const router = useRouter();
  const [objetivo, setObjetivo] = useState("");
  const [fecha, setFecha] = useState("");
  // Simulación de cálculo
  const plazos = objetivo && fecha ? 12 : "";
  const cantidadAhorrar = objetivo && plazos ? (Number(objetivo) / Number(plazos)).toFixed(2) : "";
  const rendimiento = objetivo ? (Number(objetivo) * 0.05).toFixed(2) : "";
  return (
    <div className="modal-overlay">
      <div className="modal-content access-code-modal">
        <h3>Ahorro Individual</h3>
        <form className="group-form" onSubmit={e => { e.preventDefault(); onDone(); }}>
          <label>
            Objetivo (Monto total)
            <input type="number" name="objetivo" value={objetivo} onChange={e => setObjetivo(e.target.value)} />
            <span className="input-help">¿Cuánto quieres ahorrar?</span>
          </label>
          <label>
            Fecha del Objetivo
            <input type="date" name="fecha" value={fecha} onChange={e => setFecha(e.target.value)} />
            <span className="input-help">¿Para cuándo quieres lograrlo?</span>
          </label>
          <div className="group-summary" style={{marginLeft:0, marginTop:'1.5rem'}}>
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
          </div>
          <div className="modal-actions">
            <button type="button" onClick={() => router.push('/choose-saving')} className="modal-btn">
              Atrás
            </button>
            <button type="submit" className="modal-btn primary">
              Aceptar
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
