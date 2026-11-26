<!-- PORTAL FOOTER -->
<footer
    class="px-6 sm:px-8 py-3.5 border-t border-slate-200/80 bg-white text-xs text-slate-500 flex flex-col sm:flex-row items-center justify-between gap-2 shrink-0">
    <div class="flex items-center gap-2.5 flex-wrap justify-center sm:justify-start">
        <span class="text-[11px] text-slate-400">© {{ date('Y') }} {{ $appBrandName ?? 'Presensi Makerindo' }} · {{ $appBrandSlogan ?? 'Sistem Presensi GPS & Foto Makerindo' }}</span>
    </div>
    <span class="inline-flex items-center px-2.5 py-0.5 rounded-md bg-slate-100 border border-slate-200 text-[11px] font-mono font-semibold text-slate-600">
        {{ $appVersionFull ?? 'v1.0.0 (Build 1)' }}
    </span>
</footer>
