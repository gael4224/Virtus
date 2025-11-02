"use client";
import React from "react";
import IndividualModal from "../IndividualModal";

export default function IndividualPage() {
  // Reutilizamos el formulario individual, pero como página
  return (
    <div className="choose-saving-container">
      <div className="modal-content access-code-modal" style={{margin:'3rem auto'}}>
        <IndividualModal onDone={() => {}} onClose={() => {}} />
      </div>
    </div>
  );
}
