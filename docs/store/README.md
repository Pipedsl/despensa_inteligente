# Store listings

Textos listos para pegar en Google Play Console y App Store Connect.

- [`play-store.md`](./play-store.md) — listing de Google Play
- [`app-store.md`](./app-store.md) — listing de App Store Connect

## Qué falta además de los textos

Cada tienda además de textos pide **recursos visuales**:

### Google Play (obligatorio)
- Ícono 512×512 PNG (alpha ok)
- Feature graphic 1024×500 JPG/PNG (sin alpha)
- Screenshots: mínimo 2, máximo 8 — recomendado 1080×1920

### App Store (obligatorio)
- Ícono 1024×1024 PNG (sin alpha, sin bordes redondeados)
- Screenshots 6.7" (iPhone 15/16 Pro Max): 1290×2796 — mínimo 3
- Screenshots 6.5" (iPhone 14 Plus): 1242×2688 — opcional
- Screenshot iPad 13" (si se publica para iPad): 2064×2752

Todos bloqueados por diseño.

## Decisión tomada: IAP nativo en iOS (Opción A)

Apple exige usar **StoreKit / In-App Purchase** para suscripciones digitales; Flow.cl no es válido como pasarela dentro de iOS.

**Camino elegido: implementar IAP nativo iOS cuando toque publicar en App Store.** Aceptamos la comisión de Apple (30% año 1, 15% año 2+).

### Implicancias técnicas (para cuando volvamos)
- Paquete Flutter sugerido: `in_app_purchase` (oficial de Flutter team) o `purchases_flutter` (RevenueCat, wrapper pago pero más fácil)
- Crear el producto en App Store Connect: `pro_mensual` como Auto-Renewable Subscription
- Backend: agregar endpoint que valide receipts de Apple contra los servidores de Apple (igual que hoy se valida Flow)
- Firestore: extender `usuarios/{uid}` con `applePurchaseReceipt` para tracking
- El estado Pro en el backend tiene que considerar que puede venir de Flow (Android/web) o Apple (iOS)
- Alternativa cross-platform: RevenueCat puede unificar Apple + Google + Stripe/Flow y te da webhooks únicos

### Por ahora
- El código actual usa Flow en UpgradeScreen
- Si el usuario abre la app en iOS, el botón "Actualizar a Pro" redirigiría a Flow, pero Apple podría rechazar la app en review
- **Antes de enviar a App Review**: ocultar el botón de upgrade en iOS y/o implementar IAP nativo
