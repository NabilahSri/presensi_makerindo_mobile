<!-- Modal Pratinjau & Zoom Foto Presensi -->
<div id="attendance-photo-zoom-modal"
    class="fixed inset-0 z-50 hidden flex-col bg-slate-950/85 backdrop-blur-xs p-3 sm:p-6 select-none"
    role="dialog" aria-modal="true" aria-labelledby="photo-zoom-title">

    <!-- Top Control Bar -->
    <div class="w-full max-w-5xl mx-auto flex flex-wrap items-center justify-between gap-3 pb-3 text-white">
        <div class="min-w-0">
            <h3 id="photo-zoom-title" class="text-sm sm:text-base font-bold text-white truncate">Foto Presensi</h3>
            <p id="photo-zoom-subtitle" class="text-xs text-slate-300 font-mono truncate mt-0.5"></p>
        </div>

        <div class="flex items-center gap-1.5 sm:gap-2 shrink-0">
            <button type="button" onclick="adjustPhotoZoom(-0.25)"
                class="h-9 w-9 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white flex items-center justify-center transition cursor-pointer"
                title="Perkecil">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                </svg>
            </button>
            <button type="button" id="photo-zoom-level" onclick="resetPhotoZoom()"
                class="h-9 px-3 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white text-xs font-mono font-bold transition cursor-pointer"
                title="Klik untuk kembalikan ke 100%">
                100%
            </button>
            <button type="button" onclick="adjustPhotoZoom(0.25)"
                class="h-9 w-9 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white flex items-center justify-center transition cursor-pointer"
                title="Perbesar">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
            </button>
            <a id="photo-zoom-external" href="#" target="_blank" rel="noopener"
                class="h-9 px-3 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white text-xs font-semibold inline-flex items-center gap-1.5 transition"
                title="Buka gambar asli di tab baru">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
                <span class="hidden sm:inline">Buka Asli</span>
            </a>
            <button type="button" onclick="closeAttendancePhotoModal()"
                class="h-9 w-9 rounded-xl bg-rose-500/80 hover:bg-rose-500 text-white flex items-center justify-center transition cursor-pointer"
                title="Tutup (Esc)">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>
    </div>

    <!-- Zoomable Viewport -->
    <div id="photo-zoom-stage"
        class="flex-1 w-full max-w-5xl mx-auto rounded-2xl bg-slate-900/70 border border-white/10 overflow-hidden flex items-center justify-center relative cursor-zoom-in">
        <img id="photo-zoom-img" src="" alt="Foto Presensi" draggable="false"
            class="max-h-full max-w-full object-contain transition-transform duration-150 ease-out will-change-transform" />
    </div>

    <p class="text-center text-[11px] text-slate-400 pt-2.5">
        Gunakan tombol <strong>+ / -</strong>, <strong>gulir tetikus</strong>, atau <strong>klik ganda</strong> pada foto untuk memperbesar. Geser foto saat diperbesar.
    </p>
</div>

<script>
    (function () {
        let scale = 1;
        let translateX = 0;
        let translateY = 0;
        let isDragging = false;
        let startX = 0;
        let startY = 0;

        function applyTransform() {
            const img = document.getElementById('photo-zoom-img');
            const label = document.getElementById('photo-zoom-level');
            const stage = document.getElementById('photo-zoom-stage');
            if (!img) return;

            if (scale <= 1) {
                translateX = 0;
                translateY = 0;
            }

            img.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
            if (label) label.textContent = `${Math.round(scale * 100)}%`;
            if (stage) {
                stage.style.cursor = scale > 1 ? (isDragging ? 'grabbing' : 'grab') : 'zoom-in';
            }
        }

        window.openAttendancePhotoModal = function (url, title, subtitle) {
            const modal = document.getElementById('attendance-photo-zoom-modal');
            const img = document.getElementById('photo-zoom-img');
            const titleEl = document.getElementById('photo-zoom-title');
            const subtitleEl = document.getElementById('photo-zoom-subtitle');
            const extLink = document.getElementById('photo-zoom-external');
            if (!modal || !img) return;

            scale = 1;
            translateX = 0;
            translateY = 0;
            img.src = url;
            if (titleEl) titleEl.textContent = title || 'Foto Presensi';
            if (subtitleEl) subtitleEl.textContent = subtitle || '';
            if (extLink) extLink.href = url;

            applyTransform();
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        };

        window.openPhotoZoomModal = window.openAttendancePhotoModal;

        window.closeAttendancePhotoModal = function () {
            const modal = document.getElementById('attendance-photo-zoom-modal');
            if (!modal) return;
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        };

        window.adjustPhotoZoom = function (delta) {
            scale = Math.min(4, Math.max(0.5, Number((scale + delta).toFixed(2))));
            applyTransform();
        };

        window.resetPhotoZoom = function () {
            scale = 1;
            translateX = 0;
            translateY = 0;
            applyTransform();
        };

        document.addEventListener('DOMContentLoaded', function () {
            const modal = document.getElementById('attendance-photo-zoom-modal');
            const stage = document.getElementById('photo-zoom-stage');
            if (!modal || !stage) return;

            // Scroll wheel zoom
            stage.addEventListener('wheel', function (e) {
                e.preventDefault();
                const delta = e.deltaY < 0 ? 0.25 : -0.25;
                window.adjustPhotoZoom(delta);
            }, { passive: false });

            // Double click toggle zoom 100% <-> 200%
            stage.addEventListener('dblclick', function () {
                if (scale > 1) {
                    window.resetPhotoZoom();
                } else {
                    scale = 2;
                    applyTransform();
                }
            });

            // Drag to pan when zoomed in
            stage.addEventListener('mousedown', function (e) {
                if (scale <= 1) return;
                isDragging = true;
                startX = e.clientX - translateX;
                startY = e.clientY - translateY;
                applyTransform();
            });

            window.addEventListener('mousemove', function (e) {
                if (!isDragging) return;
                translateX = e.clientX - startX;
                translateY = e.clientY - startY;
                applyTransform();
            });

            window.addEventListener('mouseup', function () {
                if (!isDragging) return;
                isDragging = false;
                applyTransform();
            });

            // Close on clicking backdrop outside stage/header
            modal.addEventListener('click', function (e) {
                if (e.target === modal) {
                    window.closeAttendancePhotoModal();
                }
            });

            // Close on Escape
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape' && !modal.classList.contains('hidden')) {
                    window.closeAttendancePhotoModal();
                }
            });
        });
    })();
</script>
