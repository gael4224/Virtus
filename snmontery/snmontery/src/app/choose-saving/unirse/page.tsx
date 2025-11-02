"use client";
import React from "react";
import JoinGroupModal from "../JoinGroupModal";

export default function UnirsePage() {
  // Reutilizamos el formulario de unirse, pero como página
  return (
    <div className="choose-saving-container">
      <div className="modal-content join-group-modal" style={{margin:'3rem auto'}}>
        <JoinGroupModal onDone={() => {}} onClose={() => {}} />
      </div>
    </div>
  );
}
