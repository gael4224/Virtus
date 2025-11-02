"use client";
import React from "react";
import GroupFormModal from "../GroupFormModal";
import "../choose-saving.css";

export default function CrearGrupoPage() {
  // Reutilizamos el formulario de grupo, pero como página
  return (
    <div className="choose-saving-container">
      <GroupFormModal onDone={() => {}} onClose={() => {}} showOverlay={false} />
    </div>
  );
}
