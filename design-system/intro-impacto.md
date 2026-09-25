# Prompt: Intro animada "Impacto" — Landing DCEP

## Objetivo
Crear una intro animada de ~3,3 segundos que se reproduce al entrar a la landing (`index.html`) de DCEP (Diego Cipriano Entrenamiento de Pádel). Tiene que transmitir **potencia, precisión y alto rendimiento** —el lema de la marca es *"Explosividad. Técnica. Control."*— y terminar revelando la landing sin corte, como si el golpe "abriera" la página.

## Estética
- **Fondo:** negro `#050505`, con viñeta sutil en los bordes y grano de película muy leve (opacidad ≤ 4 %).
- **Color principal:** verde lima neón `#bfff00`, siempre con glow (`drop-shadow` / `feGaussianBlur`, ej. `0 0 20px rgba(191,255,0,0.5)`).
- **Secundarios:** blanco (costura de la pelota, destellos) y grises `#121212` / `#1a1a1a` (cuerpo de la paleta).
- **Tipografía:** Lexend 900 itálica, igual que el título "DCEP" de la landing.
- **Estilo gráfico:** vectorial y limpio, siluetas con bordes neón, sin fotorrealismo. Cinematográfico por el timing (cámara lenta, impacto), no por el detalle.

## Elementos
1. **Pelota de pádel:** círculo verde lima con la costura curva blanca característica (dos arcos en S). Glow neón. Sombra elíptica difusa en el piso.
2. **Piso:** una línea horizontal fina neón al 65 % de la altura de la pantalla, casi invisible (opacidad 10 %), que se ilumina en cada rebote.
3. **Paleta de pádel** (basada en paletas reales tipo Bullpadel/Wilson): debe leerse claramente como paleta de pádel (sin cuerdas; no es una raqueta de tenis).
   - **Proporciones:** mango ~30 % del largo, corazón ~13 %, cara ~57 %.
   - **Cara en forma de lágrima/diamante:** ancha arriba (redondeada) y angostándose hacia el corazón. Textura de carbono (damero sutil) y **borde neón**.
   - **Perforaciones:** grilla densa de agujeros grandes en filas alternadas, cubriendo casi toda la cara, con margen libre en el borde y sin agujeros en la zona baja cerca del corazón.
   - **Corazón:** dos brazos que bajan hacia el mango con un hueco triangular invertido.
   - **Mango:** grip encintado (líneas diagonales), tapa neón en la punta y **cordón** colgando.

## Guion (timeline)
| Tiempo | Qué pasa |
|---|---|
| **0,00 – 0,30 s** | Negro total. Aparecen la viñeta y el grano. Silencio visual: crea expectativa. |
| **0,30 – 1,40 s** | La pelota cae desde arriba (fuera de cuadro) y **rebota 3 veces**, cada bote más bajo y más rápido (física real, ease de rebote). En cada contacto: *squash & stretch* (se achata ~20 % en el piso y se estira al subir), la línea del piso se enciende en ese punto y sale un anillo de onda tenue. La sombra crece al bajar y se achica al subir. |
| **1,40 – 2,20 s** | Tras el 3.er bote la pelota sube a la altura del golpe y **el tiempo se ralentiza** (≈ 0,25×). La paleta entra desde la izquierda en un arco de swing (de atrás hacia adelante), con **estela de movimiento** neón. La pelota flota casi quieta, girando despacio. |
| **2,20 s — IMPACTO** | Contacto paleta–pelota. **Flash** verde de pantalla completa (≈ 60 ms, opacidad 35 %), **onda expansiva** (anillo que se agranda y se desvanece), **chispas/partículas** neón que salen del punto de contacto, la pelota se deforma contra la paleta y un **camera shake** breve (≈ 150 ms, ±6 px). |
| **2,20 – 2,90 s** | El tiempo vuelve a velocidad real de golpe. La pelota sale disparada **hacia la cámara**: escala de 1× hasta cubrir toda la pantalla, con estela radial / motion blur. La paleta sigue su recorrido y sale de cuadro. |
| **2,90 – 3,30 s** | Cuando la pelota llena la pantalla, se convierte en un círculo verde lima sólido que hace un **iris-out** (una máscara circular que se abre desde el centro) y revela la landing. Sincronizado, el título "DCEP" de la landing hace un *punch-in* (escala 1,15 → 1 con leve rebote). Fin: el overlay se elimina del DOM. |

## Comportamiento
- **Frecuencia:** una vez por sesión (`sessionStorage`, clave `dcep_intro_seen`). Si el storage no está disponible (modo privado, bloqueado), mostrar la intro igual y no romper nada: todo acceso envuelto en `try/catch`.
- **Saltar:** botón "SALTAR" discreto abajo a la derecha (texto 10 px, mayúsculas, tracking amplio, gris que pasa a neón en hover), visible desde 0,5 s. También se salta con tap/clic en cualquier parte o con la tecla `Esc`. Al saltar: fundido del overlay en 250 ms y la landing queda en su estado final.
- **Accesibilidad:** si el usuario tiene `prefers-reduced-motion: reduce`, **no** mostrar la intro. El overlay lleva `aria-hidden="true"`; el botón Saltar es accesible por teclado.
- **Sin sonido.**
- **Sin bloquear:** la landing se renderiza normalmente debajo; la intro es una capa `position: fixed` encima (`z-index` alto). Si el JS de la animación falla, la landing tiene que verse igual.

## Restricciones técnicas
- **Stack:** SVG inline + **GSAP** (desde `cdnjs.cloudflare.com`), dentro de `index.html`. Sin imágenes, sin video, sin frameworks nuevos. La app es HTML estático con Tailwind por CDN y se publica en Vercel.
- **Rendimiento:** animar solo `transform` y `opacity` (y filtros livianos). Objetivo: 60 fps en un celular de gama media. Peso agregado ≤ 50 KB sin contar GSAP.
- **Responsive:** composición centrada que funcione de 360 px a 1920 px de ancho, vertical y horizontal. En mobile la paleta y la pelota escalan en proporción al lado menor de la pantalla.
- **Código:** separado y prolijo (un `<div id="intro">` con su SVG, un bloque `<style>` y un `<script>` propios), comentado en español, siguiendo el estilo del resto del proyecto.

## Criterios de aceptación
- [ ] La secuencia completa dura entre 3 y 3,5 s y se lee claramente: rebotes → cámara lenta → impacto → pelota a cámara → revelado.
- [ ] La paleta se reconoce como paleta de pádel a primera vista.
- [ ] El impacto se *siente*: flash + onda + chispas + shake en el mismo instante.
- [ ] El revelado deja la landing exactamente en su estado normal, sin saltos de layout.
- [ ] Se ve una sola vez por sesión; al recargar en la misma pestaña no vuelve a aparecer.
- [ ] "Saltar", tap y `Esc` funcionan desde 0,5 s.
- [ ] Con "reducir movimiento" activado no aparece.
- [ ] Sin errores en consola; la landing funciona aunque GSAP no cargue.
- [ ] Probado en 375 px (mobile) y 1440 px (desktop).
