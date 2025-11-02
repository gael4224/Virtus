# 🚀 Guía de Despliegue en Vercel

Esta guía te ayudará a desplegar tu aplicación de grupos de ahorro en Vercel paso a paso.

## 📋 Prerequisitos

1. ✅ Tu proyecto está en GitHub (`gael4224/Virtus`)
2. ✅ Cuenta de Vercel (crear en https://vercel.com/signup)
3. ✅ App ID de Privy (obtener en https://dashboard.privy.io/)

---

## 🔧 Paso 1: Preparar Variables de Entorno

Antes de desplegar, necesitas tener estas variables de entorno:

### Variables requeridas:
- `NEXT_PUBLIC_PRIVY_APP_ID` - Tu App ID de Privy
- `NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL` - URL del RPC (opcional, tiene valor por defecto)
- `NEXT_PUBLIC_CONTRATO_ADDRESS` - Dirección del contrato desplegado (opcional, tiene valor por defecto)

**Valores por defecto actuales:**
```
NEXT_PUBLIC_PRIVY_APP_ID=cmhfxhj1p01spl90cv8voyekm
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
NEXT_PUBLIC_CONTRATO_ADDRESS=0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec
```

---

## 🌐 Paso 2: Desplegar desde el Dashboard de Vercel (Recomendado)

### 2.1. Crear cuenta e iniciar sesión
1. Ve a https://vercel.com/signup
2. Inicia sesión con GitHub (recomendado para integración automática)

### 2.2. Importar proyecto
1. En el dashboard de Vercel, haz clic en **"Add New..."** → **"Project"**
2. Busca tu repositorio `gael4224/Virtus`
3. Haz clic en **"Import"**

### 2.3. Configurar el proyecto

#### Configuración básica:
- **Framework Preset:** Next.js (debe detectarse automáticamente)
- **Root Directory:** `snmontery/snmontery` ⚠️ **IMPORTANTE**
- **Build Command:** `npm run build` (se ejecutará automáticamente dentro de `snmontery/snmontery`)
- **Output Directory:** `.next` (default)
- **Install Command:** `npm install` (se ejecutará automáticamente dentro de `snmontery/snmontery`)

#### Variables de entorno:
En la sección **"Environment Variables"**, agrega:

```
NEXT_PUBLIC_PRIVY_APP_ID=cmhfxhj1p01spl90cv8voyekm
NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
NEXT_PUBLIC_CONTRATO_ADDRESS=0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec
```

Para cada variable:
1. **Key:** nombre de la variable
2. **Value:** valor de la variable
3. **Environments:** selecciona todas (Production, Preview, Development)

### 2.4. Desplegar
1. Haz clic en **"Deploy"**
2. Espera a que el build termine (toma ~2-5 minutos)
3. Una vez completado, obtendrás una URL como: `https://tu-proyecto.vercel.app`

---

## 💻 Paso 3: Desplegar desde la Terminal (Alternativa)

Si prefieres usar la CLI de Vercel:

### 3.1. Instalar Vercel CLI
```bash
npm install -g vercel
```

### 3.2. Iniciar sesión
```bash
vercel login
```

### 3.3. Configurar y desplegar
```bash
cd snmontery/snmontery
vercel
```

Durante la configuración:
- **Set up and deploy?** → Y
- **Which scope?** → Selecciona tu cuenta
- **Link to existing project?** → N (primera vez)
- **Project name:** → Deja el nombre sugerido o personaliza
- **Directory:** → `./` (ya estamos en snmontery/snmontery)
- **Override settings?** → Y
  - **Root directory:** `snmontery/snmontery`
  - **Build command:** `npm run build`
  - **Output directory:** `.next`

### 3.4. Configurar variables de entorno
```bash
vercel env add NEXT_PUBLIC_PRIVY_APP_ID
vercel env add NEXT_PUBLIC_ARBITRUM_SEPOLIA_RPC_URL
vercel env add NEXT_PUBLIC_CONTRATO_ADDRESS
```

Ingresa los valores cuando se te soliciten.

### 3.5. Desplegar a producción
```bash
vercel --prod
```

---

## 🔍 Paso 4: Verificar el Despliegue

Una vez desplegado:

1. **Visita tu URL:** `https://tu-proyecto.vercel.app`
2. **Verifica que:**
   - ✅ La página carga correctamente
   - ✅ Puedes iniciar sesión con Privy
   - ✅ Puedes conectar tu wallet (MetaMask/Phantom)
   - ✅ Las transacciones funcionan en Arbitrum Sepolia

---

## ⚙️ Paso 5: Configuración Avanzada (Opcional)

### 5.1. Dominio personalizado
1. Ve a **Settings** → **Domains**
2. Agrega tu dominio personalizado
3. Configura los DNS según las instrucciones

### 5.2. Auto-deploy desde GitHub
- Por defecto, Vercel despliega automáticamente cuando haces push a `main` o `master`
- Puedes cambiar la branch en **Settings** → **Git**

### 5.3. Preview Deployments
- Cada Pull Request crea un preview deployment automático
- Útil para probar cambios antes de producción

---

## 🐛 Solución de Problemas Comunes

### Error: "Build failed"
**Solución:**
- Verifica que el **Root Directory** esté configurado como `snmontery/snmontery`
- Revisa los logs de build en Vercel para ver el error específico

### Error: "Module not found"
**Solución:**
- Asegúrate de que `package.json` esté en `snmontery/snmontery/`
- Verifica que todas las dependencias estén listadas en `package.json`

### Error: "Environment variables not found"
**Solución:**
- Verifica que las variables de entorno estén configuradas en Vercel
- Asegúrate de que empiecen con `NEXT_PUBLIC_` para que estén disponibles en el cliente

### Error: "Privy not working"
**Solución:**
- Verifica que `NEXT_PUBLIC_PRIVY_APP_ID` esté configurado correctamente
- Asegúrate de que el App ID sea válido en el dashboard de Privy

---

## 📝 Notas Importantes

1. **HTTPS:** Vercel despliega automáticamente con HTTPS, así que las embedded wallets de Privy funcionarán correctamente.

2. **Variables de entorno:** Todas las variables que necesites en el cliente deben empezar con `NEXT_PUBLIC_`.

3. **Build time:** El primer build puede tardar más tiempo (~5 minutos). Los siguientes builds son más rápidos.

4. **Límites gratuitos:** El plan gratuito de Vercel incluye:
   - 100GB de bandwidth por mes
   - Deployments ilimitados
   - Builds ilimitados

---

## 🎉 ¡Listo!

Una vez completado el despliegue, tu aplicación estará disponible en:
- **Producción:** `https://tu-proyecto.vercel.app`
- **Preview:** `https://tu-proyecto-git-branch.vercel.app` (para cada branch/PR)

¡Felicitaciones! Tu aplicación de grupos de ahorro está ahora en producción. 🚀

