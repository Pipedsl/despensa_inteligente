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

## Decisión pendiente: suscripciones en iOS

Apple exige usar **StoreKit / In-App Purchase** para suscripciones digitales. Flow.cl no es aceptable como pasarela en iOS. Ver nota en `app-store.md` sección "In-App Purchases".

Opciones:
- A) Implementar IAP nativo iOS (Apple 15-30% comisión)
- B) No ofrecer Pro en iOS (solo Android + web)
- C) Solo upgrade via web/Android, iOS recibe el estado Pro si el mismo usuario pagó en otra plataforma
