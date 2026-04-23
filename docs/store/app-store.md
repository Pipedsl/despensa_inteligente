# Apple App Store — Listing

Textos para pegar en App Store Connect → App Information + Version Info.

---

## App Name
*(máx. 30 caracteres — visible junto al ícono)*

```
Despensa Inteligente
```
**20/30** ✅

---

## Subtitle
*(máx. 30 caracteres — línea secundaria debajo del nombre)*

```
Tu despensa con IA
```
**18/30** ✅

### Alternativas
- `Controlá tu despensa con IA` (27)
- `Recetas desde tu despensa` (25)
- `Menos comida botada` (19)

---

## Promotional Text
*(máx. 170 caracteres — editable sin aprobación, ideal para novedades)*

```
Escanea tus productos, recibe alertas de vencimiento y descubrí qué cocinar con lo que ya tenés. Recetas generadas por IA según tu despensa real.
```
**147/170** ✅

---

## Description
*(máx. 4000 caracteres)*

```
Despensa Inteligente te ayuda a dejar de botar comida y a decidir qué cocinar con lo que ya tenés en casa.

REGISTRÁ TU DESPENSA EN SEGUNDOS
Escaneá el código de barras de tus productos y la app los identifica al instante. Agregá cantidad, fecha de vencimiento y listo.

CONTROL DE VENCIMIENTOS
Recibí alertas de los productos que están por vencer. Veas qué consumir primero, qué está por caducar y qué todavía tiene tiempo.

RECETAS GENERADAS POR IA
¿No sabés qué cocinar? La app sugiere recetas personalizadas con los ingredientes reales de tu despensa. Recibís pasos, cantidades y tiempo estimado.

COMPARTÍ EL HOGAR
Invitá a tu pareja, familia o roommates a la misma despensa. Todos ven qué hay, qué falta y qué vence pronto.

PLAN GRATIS
• 3 recetas por mes
• 30 productos en tu despensa
• 1 hogar
• Historial básico

PLAN PRO
• 50 recetas por mes con el modelo IA más potente
• 300 productos
• Hasta 3 hogares
• Historial completo
• Sin anuncios

HECHA EN CHILE
Desarrollada en Chile, en español, para familias que quieren reducir desperdicio y ahorrar en las compras.

TUS DATOS SON TUYOS
No vendemos tu información. Revisá la política:
https://despensa-inteligente-c1f9d.web.app/privacidad

USO DE LA CÁMARA
Solo para escanear códigos de barras. No guardamos ni enviamos imágenes.

SOPORTE
Escribinos a felipenavarrete.ps3@gmail.com. Leemos cada mensaje.

Condiciones del Plan Pro:
• Suscripción mensual en CLP, cobrada por Flow.cl
• Se renueva automáticamente hasta que canceles
• Podés cancelar cuando quieras
• No hay reembolsos por períodos ya pagados
Términos: https://despensa-inteligente-c1f9d.web.app/terminos
```
**1561/4000** ✅

---

## Keywords
*(máx. 100 caracteres, separadas por coma, sin espacios)*

```
despensa,recetas,IA,vencimiento,alimentos,cocina,hogar,comida,barcode,compras,nevera,familia
```
**93/100** ✅

### Notas de ASO
- "despensa" y "recetas" son los términos primarios — alta intención de búsqueda
- "IA" captura la tendencia 2026 de apps con inteligencia artificial
- "vencimiento", "alimentos", "comida" cubren el dolor concreto
- "familia" captura búsquedas tipo "app para familia"
- Evité plurales redundantes ("receta" vs "recetas") porque Apple matchea ambos

---

## What's New (v1.0.0)
*(máx. 4000 caracteres — aparece en updates)*

```
Lanzamiento inicial 🚀

Despensa Inteligente ya está disponible:

• Escaneo de códigos de barras con identificación automática
• Control de fechas de vencimiento con alertas visuales
• Recetas generadas por IA según tu despensa
• Gestión compartida de hogar entre varios miembros
• Plan Gratis y Plan Pro con más capacidad

Hecha en Chile. Cualquier idea, duda o reporte escribinos a felipenavarrete.ps3@gmail.com — leemos todo.
```
**427/4000** ✅

---

## Metadata

| Campo | Valor |
|---|---|
| **Bundle ID** | `com.webiados.despensaInteligente` |
| **SKU** | `despensa-inteligente-1` |
| **Primary category** | Food & Drink |
| **Secondary category** | Productivity |
| **Primary language** | Spanish (Mexico) — mejor cobertura LATAM que es-CL en App Store |
| **Content rights** | Contains no third-party content |
| **Age rating** | 4+ |
| **Contact email** | felipenavarrete.ps3@gmail.com |
| **Support URL** | https://despensa-inteligente-c1f9d.web.app |
| **Marketing URL** (opcional) | https://despensa-inteligente-c1f9d.web.app |
| **Privacy Policy URL** | https://despensa-inteligente-c1f9d.web.app/privacidad |

---

## App Privacy (declaración)

Apple pide declarar data collection por categorías. Marcar:

### Data Linked to You
- **Contact Info — Email Address** (para auth)
- **Contact Info — Name** (opcional, ingresado por el usuario)
- **Identifiers — User ID** (Firebase Auth UID)
- **Purchases — Purchase History** (sí, cuando usan el plan Pro)

### Data Not Collected
- Location
- Photos / Videos
- Contacts
- Health & Fitness
- Browsing History
- Search History
- Device ID
- Advertising Data
- Diagnostics (crash reporting no habilitado en v1)

### Third Parties
- **Google Firebase**: auth, Firestore, Functions (obligatorio declarar)
- **Google Gemini**: se envía el contenido de la despensa para generar recetas (NO datos personales)
- **Open Food Facts**: se envían códigos de barras (NO datos personales)
- **Flow.cl**: procesa pagos del plan Pro (datos de facturación)

---

## In-App Purchases

Apple pide declarar las suscripciones antes de enviar a review.

| Producto | Tipo | Nombre | Precio referencia |
|---|---|---|---|
| Plan Pro Mensual | Auto-Renewable Subscription | `pro_mensual` | CLP $2.990 |

⚠️ **Importante**: iOS requiere usar StoreKit / In-App Purchase para suscripciones digitales. **Flow.cl no es válido como pasarela de pago dentro de la app iOS**. Para iOS hay que implementar IAP de Apple (comisión 15-30%) o forzar al usuario a suscribirse en la web/Android.

**Decisión tomada**: implementar IAP nativo iOS (Opción A) cuando toque publicar en App Store. Aceptamos la comisión de Apple.

Ver `docs/store/README.md` para implicancias técnicas y pasos concretos.
