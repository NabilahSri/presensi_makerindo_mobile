<!-- Modal Kustom Global (Menggantikan alert / confirm / prompt bawaan browser) -->

<!-- 1. Modal Alert / Pemberitahuan -->
<div id="chrono-alert-modal"
    class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4"
    role="dialog" aria-modal="true" aria-labelledby="chrono-alert-title">
    <div class="bg-white border border-slate-200 rounded-2xl max-w-sm w-full p-6 shadow-2xl space-y-4">
        <div class="flex items-start gap-3.5">
            <div class="w-10 h-10 rounded-xl bg-amber-50 border border-amber-200 text-amber-600 flex items-center justify-center shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
                </svg>
            </div>
            <div class="min-w-0">
                <h3 id="chrono-alert-title" class="text-sm font-extrabold text-slate-900">Perhatian</h3>
                <p id="chrono-alert-message" class="text-xs text-slate-600 mt-1 leading-relaxed"></p>
            </div>
        </div>
        <div class="flex justify-end pt-2 border-t border-slate-100">
            <button type="button" onclick="closeChronoAlert()"
                class="h-9 px-4 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition cursor-pointer">
                Mengerti
            </button>
        </div>
    </div>
</div>

<!-- 2. Modal Konfirmasi Hapus / Aksi -->
<div id="chrono-confirm-modal"
    class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4"
    role="dialog" aria-modal="true" aria-labelledby="chrono-confirm-title">
    <div class="bg-white border border-slate-200 rounded-2xl max-w-sm w-full p-6 shadow-2xl space-y-4">
        <div class="flex items-start gap-3.5">
            <div class="w-10 h-10 rounded-xl bg-rose-50 border border-rose-200 text-rose-600 flex items-center justify-center shrink-0">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
            </div>
            <div class="min-w-0">
                <h3 id="chrono-confirm-title" class="text-sm font-extrabold text-slate-900">Konfirmasi Aksi</h3>
                <p id="chrono-confirm-message" class="text-xs text-slate-600 mt-1 leading-relaxed"></p>
            </div>
        </div>
        <div class="flex items-center justify-end gap-2.5 pt-2 border-t border-slate-100">
            <button type="button" onclick="closeChronoConfirm()"
                class="h-9 px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-700 text-xs font-bold transition cursor-pointer">
                Batal
            </button>
            <button type="button" id="chrono-confirm-submit-btn" onclick="submitChronoConfirm()"
                class="h-9 px-4 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition cursor-pointer">
                Ya, Hapus
            </button>
        </div>
    </div>
</div>

<!-- 3. Modal Input / Prompt (Alasan Penolakan dsb.) -->
<div id="chrono-prompt-modal"
    class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4"
    role="dialog" aria-modal="true" aria-labelledby="chrono-prompt-title">
    <div class="bg-white border border-slate-200 rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
        <div class="flex items-start justify-between gap-3">
            <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-xl bg-rose-50 border border-rose-200 text-rose-600 flex items-center justify-center shrink-0">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M12 9v2m0 4h.01M6 18L18 6M6 6l12 12" />
                    </svg>
                </div>
                <div class="min-w-0">
                    <h3 id="chrono-prompt-title" class="text-sm font-extrabold text-slate-900">Tolak Pengajuan</h3>
                    <p id="chrono-prompt-message" class="text-xs text-slate-600 mt-0.5 leading-relaxed"></p>
                </div>
            </div>
            <button type="button" onclick="closeChronoPrompt()"
                class="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition cursor-pointer">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>

        <div class="space-y-1.5">
            <label id="chrono-prompt-label" for="chrono-prompt-textarea"
                class="block text-xs font-bold text-slate-700 uppercase tracking-wider">
                Alasan Penolakan
            </label>
            <textarea id="chrono-prompt-textarea" rows="3"
                placeholder="Tuliskan alasan penolakan secara jelas..."
                class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition"></textarea>
            <p id="chrono-prompt-error" class="hidden text-xs font-semibold text-rose-600"></p>
        </div>

        <div class="flex items-center justify-end gap-2.5 pt-2 border-t border-slate-100">
            <button type="button" onclick="closeChronoPrompt()"
                class="h-9 px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-700 text-xs font-bold transition cursor-pointer">
                Batal
            </button>
            <button type="button" id="chrono-prompt-submit-btn" onclick="submitChronoPrompt()"
                class="h-9 px-4 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition cursor-pointer">
                Tolak Pengajuan
            </button>
        </div>
    </div>
</div>

<script>
    (function () {
        let pendingConfirmForm = null;
        let pendingPromptForm = null;
        let pendingPromptInputName = 'rejection_reason';

        window.chronoAlert = function (message, title) {
            const modal = document.getElementById('chrono-alert-modal');
            if (!modal) return;
            document.getElementById('chrono-alert-title').textContent = title || 'Perhatian';
            document.getElementById('chrono-alert-message').textContent = message || '';
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        };

        window.closeChronoAlert = function () {
            const modal = document.getElementById('chrono-alert-modal');
            if (!modal) return;
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        };

        window.chronoConfirmForm = function (event, form, options) {
            if (event) event.preventDefault();
            const opts = options || {};
            pendingConfirmForm = form;
            const modal = document.getElementById('chrono-confirm-modal');
            if (!modal) return false;
            document.getElementById('chrono-confirm-title').textContent = opts.title || 'Konfirmasi Hapus';
            document.getElementById('chrono-confirm-message').textContent = opts.message || 'Apakah Anda yakin ingin melanjutkan?';
            document.getElementById('chrono-confirm-submit-btn').textContent = opts.confirmText || 'Ya, Hapus';
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            return false;
        };

        window.closeChronoConfirm = function () {
            pendingConfirmForm = null;
            const modal = document.getElementById('chrono-confirm-modal');
            if (!modal) return;
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        };

        window.submitChronoConfirm = function () {
            const formToSubmit = pendingConfirmForm;
            window.closeChronoConfirm();
            if (formToSubmit) {
                formToSubmit.submit();
            }
        };

        window.chronoPromptForm = function (event, form, options) {
            if (event) event.preventDefault();
            const opts = options || {};
            pendingPromptForm = form;
            pendingPromptInputName = opts.inputName || 'rejection_reason';

            const modal = document.getElementById('chrono-prompt-modal');
            const textarea = document.getElementById('chrono-prompt-textarea');
            const errorEl = document.getElementById('chrono-prompt-error');
            if (!modal || !textarea) return false;

            document.getElementById('chrono-prompt-title').textContent = opts.title || 'Tolak Pengajuan';
            document.getElementById('chrono-prompt-message').textContent = opts.message || 'Masukkan alasan penolakan untuk pengajuan ini.';
            document.getElementById('chrono-prompt-label').textContent = opts.label || 'Alasan Penolakan (Wajib)';
            document.getElementById('chrono-prompt-submit-btn').textContent = opts.confirmText || 'Tolak Pengajuan';
            textarea.placeholder = opts.placeholder || 'Tuliskan alasan penolakan secara jelas...';
            textarea.value = '';
            if (errorEl) {
                errorEl.textContent = '';
                errorEl.classList.add('hidden');
            }

            modal.classList.remove('hidden');
            modal.classList.add('flex');
            setTimeout(() => textarea.focus(), 40);
            return false;
        };

        window.closeChronoPrompt = function () {
            pendingPromptForm = null;
            const modal = document.getElementById('chrono-prompt-modal');
            if (!modal) return;
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        };

        window.submitChronoPrompt = function () {
            const textarea = document.getElementById('chrono-prompt-textarea');
            const errorEl = document.getElementById('chrono-prompt-error');
            const val = textarea ? textarea.value.trim() : '';

            if (!val) {
                if (errorEl) {
                    errorEl.textContent = 'Alasan wajib diisi sebelum melanjutkan.';
                    errorEl.classList.remove('hidden');
                }
                if (textarea) textarea.focus();
                return;
            }

            const formToSubmit = pendingPromptForm;
            const inputName = pendingPromptInputName;
            window.closeChronoPrompt();
            if (formToSubmit) {
                const hiddenInput = formToSubmit.querySelector(`input[name="${inputName}"]`);
                if (hiddenInput) {
                    hiddenInput.value = val;
                }
                formToSubmit.submit();
            }
        };

        document.addEventListener('click', function (e) {
            if (e.target === document.getElementById('chrono-alert-modal')) window.closeChronoAlert();
            if (e.target === document.getElementById('chrono-confirm-modal')) window.closeChronoConfirm();
            if (e.target === document.getElementById('chrono-prompt-modal')) window.closeChronoPrompt();
        });

        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                window.closeChronoAlert();
                window.closeChronoConfirm();
                window.closeChronoPrompt();
            }
        });
    })();
</script>
