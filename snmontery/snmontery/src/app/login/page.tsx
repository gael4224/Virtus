"use client";



import { usePrivy } from "@privy-io/react-auth";
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import './login.css';

export default function LoginPage() {
  const { login, logout, ready, authenticated, user } = usePrivy();
  const router = useRouter();



  useEffect(() => {
    if (authenticated && user) {
      // Detectar si es nuevo usando localStorage
      const isNewUser = localStorage.getItem("isNewUser");
      if (isNewUser === null) {
        localStorage.setItem("isNewUser", "false");
        router.replace("/choose-saving");
      } else {
        router.replace("/dashboard");
      }
    }
  }, [authenticated, user, router]);

  if (!ready) return <div className="login-bg"><div className="login-card">Cargando...</div></div>;

  return (
    <div className="login-bg">
      {/* Logo de fondo grande */}
      <div className="logo-background"></div>
      {/* HERO PRINCIPAL */}
      <section className="hero-section">
        <h1 className="hero-title">Fondo de Ahorro Compartido</h1>
        <p className="hero-subtitle">Invierte, ahorra y gana rentabilidad con stablecoins en una plataforma segura y colaborativa.</p>
      </section>
      {/* OFERTA/LOGIN */}
      <div className="login-card">
        <h2 className="login-title">Inicia sesión para acceder a tu fondo</h2>
        <button className="login-btn" onClick={login}>Iniciar sesión con Privy</button>
        <p className="login-info">Gestiona tu ahorro, consulta tu saldo y únete a grupos de inversión.</p>
      </div>
      {/* BENEFICIOS */}
      <section className="section-scroll">
        <h2 className="section-title">¿Por qué elegirnos?</h2>
        <ul className="benefits-list">
          <li>
            <span className="benefit-icon">💰</span>
            <span><strong>Rentabilidad diaria</strong> con stablecoins y Aave</span>
          </li>
          <li>
            <span className="benefit-icon">👥</span>
            <span><strong>Ahorro colaborativo</strong> y seguro en grupos</span>
          </li>
          <li>
            <span className="benefit-icon">⚡</span>
            <span><strong>Transacciones rápidas</strong> y transparentes</span>
          </li>
          <li>
            <span className="benefit-icon">🔒</span>
            <span><strong>Seguridad blockchain</strong> con multisig</span>
          </li>
        </ul>
      </section>
      {/* TESTIMONIOS */}
      <section className="section-scroll">
        <h2 className="section-title">Historias de éxito</h2>
        <blockquote className="testimonial">
          "Gracias a la plataforma, mi grupo y yo hemos crecido nuestro fondo de manera segura y sin complicaciones."
          <footer className="testimonial-author">— Ana G.</footer>
        </blockquote>
      </section>
      {/* SOPORTE/CONTACTO */}
      <section className="section-scroll">
        <h2 className="section-title">¿Tienes dudas?</h2>
        <p style={{ marginBottom: '1rem', color: '#666' }}>Contacta a este correo:</p>
        <a href="mailto:Virtus_Oficial@gmail.com" className="contact-email">Virtus_Oficial@gmail.com</a>
      </section>
      {/* FOOTER */}
      <footer className="landing-footer">
        <div>© 2025 Fondo Compartido. Todos los derechos reservados.</div>
        <div className="footer-links">
          <a href="#">Privacidad</a> | <a href="#">Términos</a> | <a href="#">Ayuda</a>
        </div>
      </footer>
    </div>
  );
}
