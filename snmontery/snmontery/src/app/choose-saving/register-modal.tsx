import React from "react";
import "./choose-saving.css";

export default function RegisterModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="modal-overlay">
      <div className="modal-content register-modal">
        <h3>Registro</h3>
        <form className="register-form" onSubmit={e => { e.preventDefault(); onClose(); }}>
          <label>
            Nombre
            <input type="text" name="nombre" required />
          </label>
          <label>
            Email
            <input type="email" name="email" required />
          </label>
          <label>
            Contraseña
            <input type="password" name="password" required />
          </label>
          <div className="modal-actions">
            <button type="button" onClick={onClose} className="modal-btn">
              Cancelar
            </button>
            <button type="submit" className="modal-btn primary">
              Registrarse
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
