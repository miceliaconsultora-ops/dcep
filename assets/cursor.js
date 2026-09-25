// Cursor DCEP: pelotita que sigue al mouse y rueda con el movimiento.
// Reemplaza al cursor del sistema solo en dispositivos con mouse; si este script
// no corre, queda el cursor estático definido en cursor.css.
(function () {
    if (!window.matchMedia || !window.matchMedia('(pointer: fine)').matches) return;

    const root = document.documentElement;
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const CLICKABLE = 'a, button, select, label, summary, [role="button"], [onclick], .cursor-pointer, ' +
        'input[type="checkbox"], input[type="radio"], input[type="submit"], input[type="button"], input[type="file"]';
    const base = document.currentScript.src.replace(/cursor\.js.*$/, '');

    function init() {
        const cursor = document.createElement('div');
        cursor.className = 'dcep-cursor';
        cursor.innerHTML =
            `<span class="dcep-cursor-ring"></span>` +
            `<img class="dcep-cursor-ball" src="${base}cursor-ball.svg" alt="">`;
        document.body.appendChild(cursor);
        const ball = cursor.querySelector('.dcep-cursor-ball');
        root.classList.add('custom-cursor');

        let x = -100, y = -100, lastX = null;
        let angle = 0, hovering = false, visible = false, pressed = false;
        let lastTime = performance.now();

        function setVisible(v) {
            // Oculto durante la intro
            v = v && !root.classList.contains('intro-on');
            if (v !== visible) {
                visible = v;
                cursor.style.opacity = v ? '1' : '0';
            }
        }

        document.addEventListener('mousemove', e => {
            x = e.clientX;
            y = e.clientY;
            // Rueda según el desplazamiento horizontal
            if (lastX !== null) angle += (x - lastX) * 2.2;
            lastX = x;

            const t = e.target instanceof Element ? e.target : null;
            // Donde el CSS pide otro cursor (texto, deshabilitado) se muestra el del sistema
            const native = t && getComputedStyle(t).cursor !== 'none';
            setVisible(!native);
            hovering = !!(t && t.closest(CLICKABLE));
            cursor.classList.toggle('is-hover', hovering);
        }, { passive: true });

        document.addEventListener('mousedown', () => { pressed = true; });
        document.addEventListener('mouseup', () => { pressed = false; });
        document.addEventListener('mouseleave', () => setVisible(false));
        document.documentElement.addEventListener('mouseleave', () => setVisible(false));

        function frame(now) {
            const dt = Math.min(0.05, (now - lastTime) / 1000);
            lastTime = now;
            // Giro lento constante (más rápido sobre elementos clickeables)
            if (!reduceMotion) angle += dt * (hovering ? 360 : 90);
            const scale = pressed ? 0.8 : 1;
            cursor.style.transform = `translate3d(${x - 16}px, ${y - 16}px, 0) scale(${scale})`;
            ball.style.transform = `rotate(${angle}deg)`;
            if (visible && root.classList.contains('intro-on')) setVisible(false);
            requestAnimationFrame(frame);
        }
        requestAnimationFrame(frame);
    }

    if (document.body) init();
    else document.addEventListener('DOMContentLoaded', init);
})();
