
"use client";
import React from "react";
import { useRouter } from "next/navigation";
import "./choose-saving.css";

const options = [
  { label: "Crear un grupo", value: "crear" },
  { label: "Individual", value: "individual" },
  { label: "Unirse a un grupo", value: "unirse" },
];

export default function ChooseSavingPage() {
  const router = useRouter();

  const handleOptionClick = (value: string) => {
    if (value === 'crear') router.push('/choose-saving/crear-grupo');
    if (value === 'individual') router.push('/choose-saving/individual');
    if (value === 'unirse') router.push('/choose-saving/unirse');
  };

  return (
    <div className="choose-saving-container">
      <h2 className="choose-saving-title">¿Como prefieres ahorrar?</h2>
      <div className="choose-saving-options">
        {options.map((opt) => (
          <button
            key={opt.value}
            className="choose-saving-option"
            onClick={() => handleOptionClick(opt.value)}
          >
            <span className="choose-saving-radio" />
            <span className="choose-saving-label">{opt.label}</span>
          </button>
        ))}
      </div>
      <button className="skip-step-btn" onClick={() => router.push('/dashboard')}>
        Saltar este paso
      </button>
    </div>
  );
}

