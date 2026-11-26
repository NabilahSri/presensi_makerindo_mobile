@extends('layouts.app')

@section('title', 'Dasbor Eksekutif CEO - Presensi Makerindo')
@section('page_title', 'Ringkasan Eksekutif & Pengawasan Strategis (CEO)')
@section('page_subtitle', 'Analitik tingkat tinggi untuk pemantauan kedisiplinan kehadiran GPS & foto, produktivitas tugas harian, dan akses laporan direksi.')

@section('content')
    <div class="space-y-6">

        <!-- Banner Status Eksekutif (Bebas Kewajiban Presensi & Read-Only Analytics) -->
        <div class="bg-white rounded-2xl border border-slate-200 p-4 sm:px-6 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-2xs">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-slate-900 text-sky-400 flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                </div>
                <div>
                    <div class="flex items-center gap-2 flex-wrap">
                        <span class="text-xs font-extrabold uppercase tracking-wider text-slate-900">Mode Pengawasan Eksekutif (Analitik Hanya Baca)</span>
                        <span class="px-2 py-0.5 rounded text-[10px] font-mono font-bold bg-slate-100 text-slate-700 border border-slate-300">
                            Bebas Kewajiban Presensi &amp; Tugas Harian
                        </span>
                    </div>
                    <p class="text-xs text-slate-600 mt-0.5">
                        Seluruh metrik di bawah ini diolah otomatis dari presensi GPS &amp; foto, perizinan, dan laporan tugas harian pegawai.
                    </p>
                </div>
            </div>
        </div>

        <!-- 4 Kartu Metrik Utama Eksekutif -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

            <!-- 1. Total Tenaga Kerja -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between text-slate-500 mb-2">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Total Tenaga Kerja</span>
                    </div>
                    <div class="text-3xl font-extrabold text-slate-900 font-mono">{{ $stats['total_employees'] }}</div>
                </div>
                <div class="pt-3 mt-3 border-t border-slate-100 flex items-center gap-1.5 text-xs font-mono flex-wrap">
                    <span class="text-emerald-800 font-bold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">{{ $stats['kartap_count'] }} Kartap</span>
                    <span class="text-amber-900 font-bold bg-amber-50 px-2 py-0.5 rounded border border-amber-200">{{ $stats['pkwt_count'] }} PKWT</span>
                    <span class="text-sky-900 font-bold bg-sky-50 px-2 py-0.5 rounded border border-sky-200">{{ $stats['intern_count'] }} Magang</span>
                </div>
            </div>

            <!-- 2. Kehadiran Hari Ini -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between text-slate-500 mb-2">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Hadir Hari Ini</span>
                    </div>
                    <div class="text-3xl font-extrabold text-slate-900 font-mono">
                        {{ $stats['today_present_total'] }} <span class="text-sm font-normal text-slate-400">Pegawai</span>
                    </div>
                </div>
                <div class="pt-3 mt-3 border-t border-slate-100 text-xs text-slate-600 flex items-center justify-between">
                    <span>Kantor: <strong class="font-mono">{{ $stats['today_onsite'] }}</strong></span>
                    <span>WFA: <strong class="font-mono">{{ $stats['today_wfa'] }}</strong></span>
                    <span>Lembur Bln: <strong class="font-mono">{{ $stats['total_month_overtime_hours'] }}j</strong></span>
                </div>
            </div>

            <!-- 3. Tingkat Kedisiplinan Waktu -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between text-slate-500 mb-2">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Kedisiplinan Tepat Waktu</span>
                    </div>
                    <div class="text-3xl font-extrabold text-emerald-700 font-mono">
                        {{ $attendanceAnalytics['discipline_pct'] ?? 100 }}%
                    </div>
                </div>
                <div class="pt-3 mt-3 border-t border-slate-100 text-xs text-slate-600 flex items-center justify-between">
                    <span>Terlambat: <strong class="text-rose-700 font-mono">{{ $attendanceAnalytics['late_pct'] ?? 0 }}%</strong></span>
                    <span class="font-mono text-slate-500">({{ $attendanceAnalytics['late_count'] ?? 0 }} log)</span>
                </div>
            </div>

            <!-- 4. Rasio Penyelesaian Tugas (Produktivitas) -->
            <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between text-slate-500 mb-2">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Rasio Penyelesaian Tugas</span>
                    </div>
                    <div class="text-3xl font-extrabold text-sky-700 font-mono">
                        {{ $taskAnalytics['completion_rate_pct'] ?? 0 }}%
                    </div>
                </div>
                <div class="pt-3 mt-3 border-t border-slate-100 text-xs text-slate-600 flex items-center justify-between">
                    <span>Selesai: <strong class="text-emerald-700 font-mono">{{ $taskAnalytics['completed_items'] ?? 0 }}</strong></span>
                    <span>Tertunda: <strong class="text-amber-800 font-mono">{{ $taskAnalytics['pending_items'] ?? 0 }}</strong></span>
                </div>
            </div>
        </div>

        <!-- PILAR 1: TREN KEHADIRAN & KEDISIPLINAN 6 BULAN TERAKHIR -->
        <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-6 shadow-xs">
            <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-4 mb-5 border-b border-slate-100">
                <div>
                    <h2 class="text-base font-bold text-slate-900 tracking-tight">1. Tren Kehadiran &amp; Kedisiplinan 6 Bulan Terakhir</h2>
                    <p class="text-xs text-slate-600 mt-0.5">
                        Perbandingan volume kehadiran <strong>Kantor &amp; Tugas Luar</strong>, <strong>WFA</strong>, serta <strong>Ketidakhadiran</strong> dalam 6 bulan terakhir.
                    </p>
                </div>
                <div class="flex flex-wrap items-center gap-4 text-xs">
                    <div class="inline-flex items-center gap-1.5">
                        <span class="w-3 h-3 rounded-sm bg-emerald-600"></span>
                        <span class="font-semibold text-slate-700">Hadir Kantor / Tugas Luar</span>
                    </div>
                    <div class="inline-flex items-center gap-1.5">
                        <span class="w-3 h-3 rounded-sm bg-sky-500"></span>
                        <span class="font-semibold text-slate-700">WFA</span>
                    </div>
                    <div class="inline-flex items-center gap-1.5">
                        <span class="w-3 h-3 rounded-sm bg-amber-500"></span>
                        <span class="font-semibold text-slate-700">Cuti / Sakit / Izin / Alpa</span>
                    </div>
                </div>
            </div>

            <div class="space-y-3.5">
                @foreach ($attendanceTrend ?? [] as $item)
                    @php
                        $onsitePct = ($maxMonthlyTotal ?? 1) > 0 ? min(100, round(($item['onsite'] / $maxMonthlyTotal) * 100)) : 0;
                        $wfaPct = ($maxMonthlyTotal ?? 1) > 0 ? min(100, round(($item['wfa'] / $maxMonthlyTotal) * 100)) : 0;
                        $absPct = ($maxMonthlyTotal ?? 1) > 0 ? min(100, round(($item['absence'] / $maxMonthlyTotal) * 100)) : 0;
                    @endphp
                    <div class="p-3.5 rounded-xl border border-slate-200 hover:bg-slate-50 transition">
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-2">
                            <div class="flex items-center gap-2.5">
                                <span class="text-xs font-extrabold text-slate-900 font-mono w-24">{{ $item['label'] }}</span>
                                <span class="px-2 py-0.5 rounded text-[10px] font-mono font-bold bg-emerald-50 text-emerald-800 border border-emerald-200">
                                    Disiplin {{ $item['discipline_pct'] }}%
                                </span>
                            </div>
                            <div class="flex flex-wrap items-center gap-4 text-xs font-mono">
                                <span class="text-emerald-700 font-semibold">Kantor: {{ $item['onsite'] }}</span>
                                <span class="text-sky-700 font-semibold">WFA: {{ $item['wfa'] }}</span>
                                <span class="text-amber-800 font-semibold">Izin/Sakit/Alpa: {{ $item['absence'] }}</span>
                                <span class="text-rose-700 font-semibold">Terlambat: {{ $item['late'] }}</span>
                                <span class="text-slate-900 font-extrabold">Total: {{ $item['total'] }} log</span>
                            </div>
                        </div>

                        <div class="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden flex gap-0.5 p-0.5">
                            @if ($item['onsite'] > 0)
                                <div class="bg-emerald-600 h-full rounded-l-full transition-all" style="width: {{ max(4, $onsitePct) }}%"></div>
                            @endif
                            @if ($item['wfa'] > 0)
                                <div class="bg-sky-500 h-full transition-all" style="width: {{ max(3, $wfaPct) }}%"></div>
                            @endif
                            @if ($item['absence'] > 0)
                                <div class="bg-amber-500 h-full rounded-r-full transition-all" style="width: {{ max(3, $absPct) }}%"></div>
                            @endif
                        </div>
                    </div>
                @endforeach
            </div>
        </div>

        <!-- PILAR 2: EVALUASI PRODUKTIVITAS & PENYELESAIAN TUGAS (TASK COMPLETION ANALYTICS) -->
        <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-6 shadow-xs flex flex-col justify-between">
            <div>
                <div class="pb-4 mb-4 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h2 class="text-base font-bold text-slate-900 tracking-tight">2. Evaluasi Produktivitas &amp; Tugas Harian</h2>
                        <p class="text-xs text-slate-600 mt-0.5">Perbandingan capaian tugas selesai, tugas tertunda, dan tugas tambahan di luar rencana.</p>
                    </div>
                    <a href="{{ route('reports.daily-tasks') }}" class="text-xs font-bold text-sky-700 hover:underline shrink-0">
                        Detail Tugas &rarr;
                    </a>
                </div>

                <div class="space-y-4">
                    <!-- Rasio Penyelesaian Tugas -->
                    <div>
                        <div class="flex items-center justify-between text-xs mb-1">
                            <span class="font-bold text-slate-800">Rasio Tugas Berhasil Diselesaikan</span>
                            <span class="font-mono font-bold text-emerald-700">{{ $taskAnalytics['completed_items'] }} butir ({{ $taskAnalytics['completion_rate_pct'] }}%)</span>
                        </div>
                        <div class="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden">
                            <div class="bg-emerald-600 h-full rounded-full" style="width: {{ $taskAnalytics['completion_rate_pct'] }}%"></div>
                        </div>
                    </div>

                    <!-- 3 Kartu Komparasi Item Tugas -->
                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
                        <div class="p-3.5 rounded-xl bg-slate-50 border border-slate-200">
                            <span class="text-[10px] font-bold uppercase text-emerald-800 block">Tugas Selesai</span>
                            <div class="text-xl font-extrabold font-mono text-slate-900 mt-1">{{ $taskAnalytics['completed_items'] }}</div>
                            <span class="text-[11px] text-slate-500">Tuntas sesuai target</span>
                        </div>
                        <div class="p-3.5 rounded-xl bg-slate-50 border border-slate-200">
                            <span class="text-[10px] font-bold uppercase text-amber-800 block">Tugas Tertunda</span>
                            <div class="text-xl font-extrabold font-mono text-slate-900 mt-1">{{ $taskAnalytics['pending_items'] }}</div>
                            <span class="text-[11px] text-slate-500">Dilanjutkan esok hari</span>
                        </div>
                        <div class="p-3.5 rounded-xl bg-slate-50 border border-slate-200">
                            <span class="text-[10px] font-bold uppercase text-sky-800 block">Tugas Tambahan</span>
                            <div class="text-xl font-extrabold font-mono text-slate-900 mt-1">{{ $taskAnalytics['additional_items'] }}</div>
                            <span class="text-[11px] text-slate-500">Di luar rencana pagi</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="mt-5 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-600">
                <span>Kepatuhan Laporan Hari Ini ({{ $taskAnalytics['obligated_staff'] }} staf wajib lapor):</span>
                <span class="font-mono font-bold text-slate-900">
                    {{ $taskAnalytics['today_submitted'] }} Lapor Pagi · {{ $taskAnalytics['today_completed_reports'] }} Selesai Sore
                </span>
            </div>
        </div>

        <!-- PILAR 3: AKSES LAPORAN KOMPREHENSIF & UNDUH EXCEL (EXECUTIVE REPORTING) -->
        <div class="bg-white rounded-2xl border border-slate-200 p-5 sm:p-6 shadow-xs">
            <div class="pb-4 mb-4 border-b border-slate-100">
                <h2 class="text-base font-bold text-slate-900 tracking-tight">3. Pusat Laporan Komprehensif Direksi</h2>
                <p class="text-xs text-slate-600 mt-0.5">
                    Akses cepat untuk meninjau laporan lengkap atau mengunduh berkas rekapitulasi Excel (<code>.xlsx</code>) untuk bahan rapat direksi dan evaluasi operasional.
                </p>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <!-- Laporan 1: Presensi -->
                <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between gap-3">
                    <div>
                        <div class="text-xs font-extrabold text-slate-900 uppercase tracking-wider">Laporan Presensi &amp; Jam Kerja</div>
                        <p class="text-xs text-slate-600 mt-1">Rincian kehadiran GPS &amp; Foto, WFA, Tugas Luar, keterlambatan, dan jam lembur pegawai.</p>
                    </div>
                    <div class="flex items-center gap-2 pt-2 border-t border-slate-200/80">
                        <a href="{{ route('reports.attendances') }}"
                            class="flex-1 h-8 inline-flex items-center justify-center rounded-lg bg-white hover:bg-slate-100 border border-slate-300 text-slate-800 text-xs font-bold transition">
                            Lihat Laporan
                        </a>
                        <a href="{{ route('reports.attendances.export') }}"
                            class="h-8 px-3 inline-flex items-center justify-center rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition">
                            Unduh Excel
                        </a>
                    </div>
                </div>

                <!-- Laporan 2: Produktivitas Tugas Harian -->
                <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between gap-3">
                    <div>
                        <div class="text-xs font-extrabold text-slate-900 uppercase tracking-wider">Kinerja &amp; Tugas Harian</div>
                        <p class="text-xs text-slate-600 mt-1">Rekap rencana kerja pagi, capaian sore, tugas tertunda, dan tugas tambahan.</p>
                    </div>
                    <div class="flex items-center gap-2 pt-2 border-t border-slate-200/80">
                        <a href="{{ route('reports.daily-tasks') }}"
                            class="flex-1 h-8 inline-flex items-center justify-center rounded-lg bg-white hover:bg-slate-100 border border-slate-300 text-slate-800 text-xs font-bold transition">
                            Lihat Laporan
                        </a>
                        <a href="{{ route('reports.daily-tasks.export') }}"
                            class="h-8 px-3 inline-flex items-center justify-center rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition">
                            Unduh Excel
                        </a>
                    </div>
                </div>

                <!-- Laporan 3: Pengajuan Izin & WFA -->
                <div class="p-4 rounded-xl bg-slate-50 border border-slate-200 flex flex-col justify-between gap-3">
                    <div>
                        <div class="text-xs font-extrabold text-slate-900 uppercase tracking-wider">Rekap Pengajuan Cuti, Izin &amp; WFA</div>
                        <p class="text-xs text-slate-600 mt-1">Distribusi permohonan cuti, tugas luar, WFA, sakit, dan izin pegawai.</p>
                    </div>
                    <div class="flex items-center gap-2 pt-2 border-t border-slate-200/80">
                        <a href="{{ route('reports.leaves') }}"
                            class="flex-1 h-8 inline-flex items-center justify-center rounded-lg bg-white hover:bg-slate-100 border border-slate-300 text-slate-800 text-xs font-bold transition">
                            Lihat Laporan
                        </a>
                        <a href="{{ route('reports.leaves.export') }}"
                            class="h-8 px-3 inline-flex items-center justify-center rounded-lg bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition">
                            Unduh Excel
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tabel Pemantauan Aktivitas Presensi Hari Ini -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
            <div class="p-5 sm:p-6 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                    <h2 class="text-base font-bold text-slate-900 tracking-tight">Riwayat Aktivitas Presensi Karyawan Terbaru</h2>
                    <p class="text-xs text-slate-600 mt-0.5">Menampilkan aktivitas presensi khusus hari ini ({{ now()->translatedFormat('d M Y') }}) melalui verifikasi GPS &amp; Foto serta formulir perizinan.</p>
                </div>
                <span class="text-xs font-mono font-bold text-slate-700 bg-slate-100 px-3 py-1.5 rounded-lg border border-slate-200">
                    Hari Ini: {{ $recentAttendances->total() }} Catatan
                </span>
            </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left text-sm text-slate-700">
                    <thead class="bg-slate-50 text-[11px] uppercase tracking-wider font-bold text-slate-600 border-b border-slate-200">
                        <tr>
                            <th class="px-5 py-3.5">Karyawan</th>
                            <th class="px-4 py-3.5">Tanggal</th>
                            <th class="px-4 py-3.5">Metode Presensi</th>
                            <th class="px-4 py-3.5">Jam Masuk</th>
                            <th class="px-4 py-3.5">Jam Pulang</th>
                            <th class="px-4 py-3.5">Status Kehadiran</th>
                            <th class="px-5 py-3.5 text-right">Jam Lembur</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @forelse($recentAttendances as $attendance)
                            <tr class="hover:bg-slate-50/70 transition-colors">
                                <td class="px-5 py-4">
                                    <div class="flex items-center gap-3">
                                        @include('partials.user-avatar', ['user' => $attendance->user, 'size' => 34, 'shape' => 'rounded-full', 'dark' => true])
                                        <div class="min-w-0">
                                            <div class="font-bold text-slate-900">{{ $attendance->user->name ?? '-' }}</div>
                                            <div class="text-xs text-slate-500 font-mono">{{ $attendance->user->email ?? '' }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-4 py-4 font-mono text-xs text-slate-700">
                                    {{ $attendance->date ? \Carbon\Carbon::parse($attendance->date)->translatedFormat('d M Y') : '-' }}
                                </td>
                                <td class="px-4 py-4 font-mono text-xs font-bold">
                                    <span class="px-2.5 py-1 rounded-md bg-slate-100 text-slate-700 border border-slate-200">
                                        {{ $attendance->method === 'FORM' ? 'FORMULIR IZIN' : 'GPS & FOTO' }}
                                    </span>
                                </td>
                                <td class="px-4 py-4 font-mono text-xs font-bold text-slate-900">
                                    {{ $attendance->time_in ? substr($attendance->time_in, 0, 5) : '-' }}
                                </td>
                                <td class="px-4 py-4 font-mono text-xs font-bold text-slate-900">
                                    {{ $attendance->time_out ? substr($attendance->time_out, 0, 5) : '-' }}
                                </td>
                                @php
                                    $execAttLabel = match ($attendance->status) {
                                        'HADIR_ON_SITE' => 'Hadir Kantor',
                                        'TUGAS_LUAR' => 'Tugas Luar',
                                        'CUTI' => 'Cuti',
                                        default => $attendance->status,
                                    };
                                @endphp
                                <td class="px-4 py-4">
                                    @if ($attendance->is_late)
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-xs font-bold bg-rose-50 text-rose-800 border border-rose-200">
                                            {{ $execAttLabel }} (Terlambat)
                                        </span>
                                    @else
                                        <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-xs font-bold bg-emerald-50 text-emerald-800 border border-emerald-200">
                                            {{ $execAttLabel }}
                                        </span>
                                    @endif
                                </td>
                                <td class="px-5 py-4 font-mono text-xs font-bold text-slate-900 text-right">
                                    {{ $attendance->overtime_hours > 0 ? '+' . $attendance->overtime_hours . ' Jam' : '-' }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="px-6 py-12 text-center text-slate-500 text-xs">
                                    Belum ada catatan presensi yang terekam pada hari ini.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @include('partials.pagination', ['paginator' => $recentAttendances])
        </div>
    </div>
@endsection
