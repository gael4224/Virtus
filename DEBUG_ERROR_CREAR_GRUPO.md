# 🐛 Debug: Error al Crear Grupo

## 🔍 Posibles Causas

### 1. Dirección del Contrato Incorrecta
- **Problema:** La dirección del contrato puede estar mal configurada
- **Solución:** Verificar que `CONTRATO_GRUPOS_AHORRO_ADDRESS` sea `0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec`

### 2. Red Incorrecta
- **Problema:** No estás en Arbitrum Sepolia
- **Solución:** Cambiar a Arbitrum Sepolia en MetaMask (Chain ID: 421614)

### 3. Wallet No Conectada
- **Problema:** La wallet no está conectada o no tiene direcciones válidas
- **Solución:** Conectar wallet en Privy y verificar que MetaMask esté conectado

### 4. Participantes Inválidos
- **Problema:** Las direcciones de participantes no son válidas
- **Solución:** Verificar que sean direcciones válidas (0x... con 42 caracteres)

### 5. Quorum Inválido
- **Problema:** El quorum calculado es mayor que el número de aprobadores
- **Solución:** Ya corregido en el código

---

## ✅ Verificación Paso a Paso

1. **Verificar Contrato:**
   - Ir a: https://sepolia-explorer.arbitrum.io/address/0x72f7a34bdbaff6228f5c4e25c0d7731ba5a46dec
   - Debe mostrar el contrato desplegado

2. **Verificar Red en MetaMask:**
   - Debe estar en "Arbitrum Sepolia"
   - Chain ID: 421614

3. **Verificar Wallet:**
   - Debe estar conectada en Privy
   - Debe tener ETH para gas

4. **Verificar Datos del Formulario:**
   - Nombre: No vacío
   - Objetivo: Número válido (ej: 0.02)
   - Fecha: Fecha futura
   - Participantes: Direcciones válidas (opcional, puede estar vacío)

---

## 🔧 Correcciones Aplicadas

He actualizado `useCrearGrupo` para:
- ✅ Validar direcciones de participantes
- ✅ Asegurar que haya al menos un aprobador (el creador)
- ✅ Validar que el quorum sea correcto
- ✅ Filtrar direcciones inválidas

---

## 📝 Para Ver el Error Específico

Abre la consola del navegador (F12) y verifica:
- El mensaje de error exacto
- En qué línea ocurre
- Qué parámetros se están pasando

---

**Si el error persiste, comparte el mensaje de error exacto de la consola del navegador.**

