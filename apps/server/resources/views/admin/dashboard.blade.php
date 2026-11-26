@extends('layouts.app')

@section('title', 'Dasbor Super Admin - Presensi Makerindo')
@section('page_title', 'Dasbor Utama')
@section('page_subtitle', 'Selamat datang, ' . auth()->user()->name)

@section('content')
    <div class="space-y-8">

        <!-- 4 Core Control Metric Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">

            <!-- Card 1: Total Karyawan & Status -->
            <div
                class="bg-white/95 p-6 rounded-3xl border border-slate-200/90 shadow-xs backdrop-blur-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Total Karyawan</span>
                        <div class="w-9 h-9 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                            </svg>
                        </div>
                    </div>
                    <div class="text-3xl font-extrabold text-slate-900 font-mono">{{ $stats['total_users'] }}</div>
                </div>
                <div class="pt-4 border-t border-slate-100 flex items-center gap-1.5 text-xs font-mono">
                    <span
                        class="text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">{{ $stats['kartap'] }}
                        Kartap</span>
                    <span
                        class="text-amber-700 font-bold bg-amber-50 px-2 py-0.5 rounded border border-amber-200">{{ $stats['pkwt'] }}
                        PKWT</span>
                    <span
                        class="text-sky-700 font-bold bg-sky-50 px-2 py-0.5 rounded border border-sky-200">{{ $stats['intern'] }}
                        Magang</span>
                </div>
            </div>

            <!-- Card 2: Presensi Real-Time Hari Ini -->
            <div
                class="bg-white/95 p-6 rounded-3xl border border-slate-200/90 shadow-xs backdrop-blur-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Presensi Hari Ini</span>
                        <div class="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                    </div>
                    <div class="text-3xl font-extrabold text-emerald-600 font-mono">
                        {{ $stats['today_onsite'] + $stats['today_wfa'] + $stats['today_tugas_luar'] }}
                    </div>
                </div>
                <div class="pt-4 border-t border-slate-100 flex items-center justify-between text-xs font-mono">
                    <span class="text-slate-600">Kantor: <strong>{{ $stats['today_onsite'] }}</strong></span>
                    <span class="text-sky-700">WFA: <strong>{{ $stats['today_wfa'] }}</strong></span>
                    <span class="text-rose-600">Terlambat: <strong>{{ $stats['today_late'] }}</strong></span>
                </div>
            </div>

            <!-- Card 3: Laporan Tugas & Pengajuan Menunggu -->
            <div
                class="bg-white/95 p-6 rounded-3xl border border-slate-200/90 shadow-xs backdrop-blur-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Tugas Harian Hari Ini</span>
                        <div class="w-9 h-9 rounded-xl bg-slate-900 text-sky-400 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                            </svg>
                        </div>
                    </div>
                    <div class="text-3xl font-extrabold text-slate-900 font-mono">
                        {{ $stats['today_reports_count'] }} <span class="text-sm font-normal text-slate-400">Laporan</span>
                    </div>
                </div>
                <div class="pt-4 border-t border-slate-100 flex items-center justify-between text-xs">
                    <span class="text-amber-700 font-semibold bg-amber-50 px-2.5 py-0.5 rounded-full border border-amber-200">
                        {{ $stats['pending_leaves_count'] }} Izin Menunggu
                    </span>
                    <a href="{{ route('reports.daily-tasks') }}" class="text-sky-600 font-semibold hover:underline">Pantau
                        &rarr;</a>
                </div>
            </div>

            <!-- Card 4: Parameter Jam Kerja & Toleransi -->
            <div
                class="bg-white/95 p-6 rounded-3xl border border-slate-200/90 shadow-xs backdrop-blur-xs flex flex-col justify-between">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <span class="text-xs font-bold uppercase tracking-wider text-slate-500">Parameter Jam Kerja</span>
                        <div class="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                    </div>
                    <div class="text-lg font-bold text-slate-900 font-mono">
                        {{ $tolerances['work_start'] }} - {{ $tolerances['work_end'] }} WIB
                    </div>
                    <div class="text-xs text-slate-500 font-mono mt-0.5">
                        +{{ $tolerances['late'] }}m Masuk • +{{ $tolerances['overtime'] }}m Lembur
                    </div>
                </div>
                <div class="pt-4 border-t border-slate-100 flex items-center justify-between text-xs">
                    <span class="text-slate-500">Penyetuju: <strong>{{ $stats['approvers_count'] }} Akun</strong></span>
                    <a href="{{ route('admin.settings.index') }}"
                        class="text-sky-600 font-semibold hover:underline">Pengaturan &rarr;</a>
                </div>
            </div>

        </div>

        <!-- 2 Column Layout: Personil Terbaru & Log Presensi -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">

            <!-- Column 1: Karyawan Terdaftar Terbaru -->
            <div class="bg-white/95 rounded-3xl border border-slate-200/90 shadow-xs overflow-hidden backdrop-blur-xs">
                <div class="p-6 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h3 class="text-base font-bold text-slate-900 tracking-tight">Personil Terdaftar Terbaru</h3>
                        <p class="text-xs text-slate-500 mt-0.5">Karyawan dan peserta magang yang baru ditambahkan ke sistem.</p>
                    </div>
                    <a href="{{ route('admin.users.index') }}"
                        class="text-xs font-semibold text-sky-600 hover:text-sky-700">Lihat Semua &rarr;</a>
                </div>

                <div class="divide-y divide-slate-100 font-sans">
                    @forelse($recentUsers as $user)
                        <div
                            class="p-4 sm:px-6 flex items-center justify-between gap-4 hover:bg-slate-50/70 transition-colors">
                            <div class="flex items-center gap-3 min-w-0">
                                @include('partials.user-avatar', ['user' => $user, 'size' => 40, 'shape' => 'rounded-xl'])
                                <div class="truncate">
                                    <h4 class="font-bold text-slate-900 text-sm truncate">{{ $user->name }}</h4>
                                    <p class="text-xs text-slate-400 font-mono truncate">{{ $user->email }}</p>
                                </div>
                            </div>

                            <div class="flex items-center gap-3 shrink-0">
                                <span
                                    class="font-mono text-[11px] font-bold px-2.5 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">
                                    {{ $user->employment_type === 'INTERN' ? 'MAGANG' : $user->employment_type }}
                                </span>

                                <a href="{{ route('admin.users.edit', $user) }}"
                                    class="p-1.5 rounded-lg text-slate-400 hover:text-sky-600 hover:bg-sky-50 transition"
                                    title="Ubah">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                            d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                    </svg>
                                </a>
                            </div>
                        </div>
                    @empty
                        <div class="p-8 text-center text-slate-400 text-xs">Belum ada karyawan terdaftar.</div>
                    @endforelse
                </div>
            </div>

            <!-- Column 2: Log Presensi Hari Ini -->
            <div class="bg-white/95 rounded-3xl border border-slate-200/90 shadow-xs overflow-hidden backdrop-blur-xs">
                <div class="p-6 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h3 class="text-base font-bold text-slate-900 tracking-tight">Log Presensi Hari Ini</h3>
                        <p class="text-xs text-slate-500 mt-0.5">Aktivitas masuk/pulang terbaru melalui GPS &amp; Foto Seluler.</p>
                    </div>
                    <span
                        class="text-xs font-mono font-bold text-slate-500 bg-slate-100 px-2.5 py-1 rounded-md border border-slate-200">
                        {{ now()->toDateString() }}
                    </span>
                </div>

                <div class="divide-y divide-slate-100 font-sans">
                    @forelse($recentAttendances as $attendance)
                        <div
                            class="p-4 sm:px-6 flex items-center justify-between gap-4 hover:bg-slate-50/70 transition-colors">
                            <div class="flex items-center gap-3 min-w-0">
                                @include('partials.user-avatar', ['user' => $attendance->user, 'size' => 36, 'shape' => 'rounded-full', 'dark' => true])
                                <div class="min-w-0">
                                    <h4 class="font-bold text-slate-900 text-sm truncate">{{ $attendance->user->name ?? '-' }}
                                    </h4>
                                    <p class="text-xs text-slate-400 font-mono">
                                        Masuk: {{ $attendance->time_in ?: '-' }} | Pulang: {{ $attendance->time_out ?: '-' }}
                                    </p>
                                </div>
                            </div>

                            <div class="flex items-center gap-2 shrink-0">
                                <span
                                    class="font-mono text-[10px] font-bold px-2 py-0.5 rounded bg-sky-50 text-sky-700 border border-sky-200">
                                    {{ $attendance->method === 'FORM' ? 'FORMULIR' : 'GPS & FOTO' }}
                                </span>

                                @if ($attendance->is_late)
                                    <span
                                        class="px-2.5 py-1 rounded-full text-[11px] font-bold font-mono bg-rose-50 text-rose-700 border border-rose-200">
                                        Terlambat
                                    </span>
                                @else
                                    <span
                                        class="px-2.5 py-1 rounded-full text-[11px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        {{ $attendance->status }}
                                    </span>
                                @endif
                            </div>
                        </div>
                    @empty
                        <div class="p-12 text-center text-slate-400 text-xs">
                            <p class="font-medium text-slate-600">Belum ada aktivitas presensi hari ini</p>
                            <p class="text-[11px] text-slate-400 mt-1">Data akan masuk saat karyawan melakukan presensi GPS &amp; Foto melalui aplikasi mobile.</p>
                        </div>
                    @endforelse
                </div>
            </div>

        </div>

        <!-- 2 Column Layout: Konfigurasi Geofence GPS Kantor & Pengajuan Cuti/Izin -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">

            <!-- Column 1: Konfigurasi Geofence GPS & Foto -->
            <div class="bg-white/95 rounded-3xl border border-slate-200/90 shadow-xs overflow-hidden backdrop-blur-xs">
                <div class="p-6 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h3 class="text-base font-bold text-slate-900 tracking-tight">Titik Geofence GPS Kantor</h3>
                        <p class="text-xs text-slate-500 mt-0.5">Acuan validasi radius kehadiran di kantor melalui GPS &amp; kamera mobile.</p>
                    </div>
                    <a href="{{ route('admin.settings.index') }}"
                        class="text-xs font-semibold text-sky-600 hover:text-sky-700">Ubah Lokasi &rarr;</a>
                </div>

                <div class="p-6 space-y-4">
                    <div class="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
                        <div class="flex items-center justify-between gap-2">
                            <span class="text-sm font-bold text-slate-900">{{ $office['name'] }}</span>
                            <span class="px-2.5 py-0.5 rounded-full text-[11px] font-mono font-bold bg-sky-100 text-sky-800 border border-sky-200">
                                Radius {{ $office['radius'] }}m
                            </span>
                        </div>
                        <p class="text-xs text-slate-500">{{ $office['address'] }}</p>
                        <div class="pt-2 border-t border-slate-200/80 flex items-center justify-between text-xs font-mono text-slate-600">
                            <span>{{ $office['latitude'] }}, {{ $office['longitude'] }}</span>
                            <a href="https://www.google.com/maps?q={{ $office['latitude'] }},{{ $office['longitude'] }}"
                                target="_blank" class="text-sky-600 font-bold hover:underline">
                                Buka Peta &rarr;
                            </a>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 gap-3 text-xs">
                        <div class="p-3.5 rounded-2xl bg-emerald-50/70 border border-emerald-200">
                            <span class="text-[11px] font-bold uppercase text-emerald-700">Bukti Foto Hari Ini</span>
                            <div class="text-xl font-extrabold font-mono text-emerald-800 mt-1">{{ $stats['today_photo_verified'] }}</div>
                            <span class="text-[11px] text-emerald-700/80">Log terverifikasi selfie</span>
                        </div>
                        <div class="p-3.5 rounded-2xl bg-rose-50/70 border border-rose-200">
                            <span class="text-[11px] font-bold uppercase text-rose-700">Sanksi Aktif</span>
                            <div class="text-xl font-extrabold font-mono text-rose-800 mt-1">{{ $stats['active_sanctions_count'] }}</div>
                            <a href="{{ route('sanctions.index') }}" class="text-[11px] font-semibold text-rose-700 hover:underline">Kelola Sanksi &rarr;</a>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Column 2: Pengajuan Cuti / Izin Terbaru -->
            <div class="bg-white/95 rounded-3xl border border-slate-200/90 shadow-xs overflow-hidden backdrop-blur-xs">
                <div class="p-6 border-b border-slate-100 flex items-center justify-between">
                    <div>
                        <h3 class="text-base font-bold text-slate-900 tracking-tight">Pengajuan Cuti / Izin Karyawan</h3>
                        <p class="text-xs text-slate-500 mt-0.5">Daftar permohonan yang perlu persetujuan atau baru
                            diperbarui.</p>
                    </div>
                    <a href="{{ route('approval.index') }}"
                        class="text-xs font-semibold text-sky-600 hover:text-sky-700">Lihat Semua
                        ({{ $stats['pending_leaves_count'] }} Menunggu) &rarr;</a>
                </div>

                <div class="divide-y divide-slate-100 font-sans">
                    @forelse($recentLeaves as $leave)
                        <div
                            class="p-4 sm:px-6 flex items-center justify-between gap-4 hover:bg-slate-50/70 transition-colors">
                            <div class="space-y-1 min-w-0">
                                <h4 class="font-bold text-slate-900 text-sm truncate">{{ $leave->user->name ?? '-' }}</h4>
                                <p class="text-xs text-slate-400 font-mono truncate">
                                    {{ $leave->type }}: {{ $leave->start_date }} s/d {{ $leave->end_date }}
                                </p>
                                @if ($leave->reason)
                                    <p class="text-[11px] text-slate-500 italic truncate">"{{ $leave->reason }}"</p>
                                @endif
                            </div>

                            <div class="flex items-center gap-2 shrink-0">
                                @if ($leave->status === 'PENDING')
                                    <span
                                        class="px-2.5 py-0.5 rounded-full text-[11px] font-bold font-mono bg-amber-50 text-amber-700 border border-amber-200">
                                        MENUNGGU
                                    </span>
                                    <a href="{{ route('approval.index') }}"
                                        class="text-xs font-bold text-sky-600 hover:underline">Tinjau</a>
                                @elseif($leave->status === 'APPROVED')
                                    <span
                                        class="px-2.5 py-0.5 rounded-full text-[11px] font-bold font-mono bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        DISETUJUI
                                    </span>
                                @else
                                    <span
                                        class="px-2.5 py-0.5 rounded-full text-[11px] font-bold font-mono bg-rose-50 text-rose-700 border border-rose-200">
                                        DITOLAK
                                    </span>
                                @endif
                            </div>
                        </div>
                    @empty
                        <div class="p-8 text-center text-slate-400 text-xs">Belum ada pengajuan cuti/izin.</div>
                    @endforelse
                </div>
            </div>

        </div>

    </div>
@endsection
