# Solución de Error de Imports

## Problema

El error mostraba que Next.js no podía encontrar el módulo `@/lib/wagmi-config`:

```
Module not found: Can't resolve '@/lib/wagmi-config'
```

## Causa

Los archivos estaban en la carpeta `lib/` en la raíz del proyecto, pero el alias `@/*` en `tsconfig.json` apunta a `./src/*`. Next.js buscaba los archivos en `src/lib/`.

## Solución

1. **Movidos los archivos a `src/lib/`**:
   - `lib/wagmi-config.ts` → `src/lib/wagmi-config.ts`
   - `lib/contract-config.ts` → `src/lib/contract-config.ts`

2. **Eliminada la carpeta `lib/`** duplicada

3. **Actualizado `tsconfig.json`**:
   - Removido `"./lib/*"` de los paths
   - Ahora solo usa `"@/*": ["./src/*"]`

## Estado Actual

- ✅ Archivos en `src/lib/wagmi-config.ts`
- ✅ Archivos en `src/lib/contract-config.ts`
- ✅ `tsconfig.json` configurado correctamente
- ✅ Todos los imports usando `@/lib/...` funcionan

## Verificación

Todos los imports deben usar:
- `@/lib/wagmi-config` → `src/lib/wagmi-config.ts`
- `@/lib/contract-config` → `src/lib/contract-config.ts`
- `@/hooks/...` → `src/hooks/...`
- `@/components/...` → `src/components/...`

