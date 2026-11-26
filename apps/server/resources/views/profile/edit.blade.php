@extends('layouts.app')

@section('title', 'Detail & Ubah Profil - Presensi Makerindo')
@section('page_title', 'Profil Pengguna & Pengaturan Akun')

@section('content')
<div class="w-full space-y-8">

    <!-- Profile Identity Hero Card -->
    <div class="bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 rounded-3xl p-6 sm:p-8 text-white border border-slate-800 shadow-sm relative overflow-hidden">
        <div class="relative z-10 flex flex-col sm:flex-row sm:items-center justify-between gap-6">
            <div class="flex items-center gap-4">
                @if ($user->profile_photo_url)
                    <button type="button"
                        onclick='openAttendancePhotoModal(@json($user->profile_photo_url), @json("Foto Profil - " . $user->name), @json($user->email))'
                        class="rounded-2xl bg-white/10 border border-slate-700/80 overflow-hidden shrink-0 shadow-inner cursor-pointer hover:ring-2 hover:ring-sky-400 transition"
                        style="width:64px;height:64px;padding:0;" title="Perbesar foto profil">
                        <img src="{{ $user->profile_photo_url }}" alt="{{ $user->name }}"
                            style="width:100%;height:100%;object-fit:cover;display:block;">
                    </button>
                @else
                    <div class="w-16 h-16 rounded-2xl bg-white/10 border border-slate-700/80 text-sky-400 font-mono font-bold text-xl flex items-center justify-center shrink-0 shadow-inner">
                        {{ strtoupper(substr($user->name, 0, 2)) }}
                    </div>
                @endif
                <div>
                    <div class="flex flex-wrap items-center gap-2 mb-1">
                        <h2 class="text-xl sm:text-2xl font-extrabold tracking-tight text-white">{{ $user->name }}</h2>
                        <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold font-mono bg-sky-500/20 text-sky-300 border border-sky-400/30">
                            {{ $user->employment_type === 'INTERN' ? 'MAGANG' : $user->employment_type }}
                        </span>
                    </div>
                    <p class="text-xs text-slate-300 font-mono">{{ $user->email }}</p>
                    <div class="flex flex-wrap items-center gap-2 mt-3">
                        @foreach($user->roles as $role)
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-bold bg-white/10 text-slate-200 border border-slate-700">
                                {{ $role->display_name ?? $role->name }}
                            </span>
                        @endforeach
                        @if($user->can_approve_leaves)
                            <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-md text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-400/30">
                                <span class="h-1.5 w-1.5 rounded-full bg-emerald-400"></span>
                                Otoritas Penyetuju Izin
                            </span>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Metode Presensi -->
            <div class="bg-slate-950/60 p-4 rounded-2xl border border-slate-800 font-mono text-xs shrink-0 space-y-1">
                <div class="text-[10px] uppercase tracking-wider text-slate-400">Metode Presensi</div>
                <div class="font-bold text-sky-400 flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span>GPS &amp; Foto Selfie</span>
                </div>
            </div>
        </div>

        <div class="absolute -right-16 -top-16 w-64 h-64 bg-sky-500/10 rounded-full blur-3xl pointer-events-none"></div>
    </div>

    <!-- Edit Profile Form Card -->
    <div class="bg-white/95 rounded-3xl border border-slate-200/90 p-6 sm:p-8 shadow-xs">
        <div class="border-b border-slate-100 pb-5 mb-6">
            <h3 class="text-base font-bold text-slate-900 tracking-tight">Formulir Pembaruan Data Profil</h3>
            <p class="text-xs text-slate-500 mt-1">Perbarui informasi identitas akun atau ganti kata sandi login Anda.</p>
        </div>

        <form action="{{ route('profile.update') }}" method="POST" enctype="multipart/form-data" class="space-y-6">
            @csrf
            @method('PUT')

            <!-- Section 0: Foto Profil -->
            <div class="pb-5 border-b border-slate-100">
                <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Foto Profil</h4>
                <div class="flex flex-col sm:flex-row sm:items-center gap-5">
                    <div id="profile-photo-preview-wrap"
                        onclick="document.getElementById('profile_photo_input').click()"
                        class="rounded-2xl bg-slate-900 border border-slate-200 text-sky-400 font-mono font-bold text-xl flex items-center justify-center shrink-0 overflow-hidden shadow-xs cursor-pointer hover:ring-2 hover:ring-sky-500 transition"
                        style="width:84px;height:84px;" title="Klik untuk memilih foto profil baru">
                        @if ($user->profile_photo_url)
                            <img id="profile-photo-preview-img" src="{{ $user->profile_photo_url }}" alt="{{ $user->name }}"
                                style="width:100%;height:100%;object-fit:cover;display:block;">
                            <span id="profile-photo-preview-initials" style="display:none;">{{ strtoupper(substr($user->name, 0, 2)) }}</span>
                        @else
                            <img id="profile-photo-preview-img" src="" alt="{{ $user->name }}"
                                style="width:100%;height:100%;object-fit:cover;display:none;">
                            <span id="profile-photo-preview-initials">{{ strtoupper(substr($user->name, 0, 2)) }}</span>
                        @endif
                    </div>

                    <div class="flex-1 min-w-0 space-y-2.5">
                        <input type="file" id="profile_photo_input" name="profile_photo"
                            accept="image/*" onchange="previewProfilePhoto(this)"
                            class="block w-full max-w-md text-xs text-slate-600 file:mr-3 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-slate-900 file:text-white hover:file:bg-slate-800 file:cursor-pointer cursor-pointer">

                        @if ($user->profile_photo_url)
                            <div>
                                <label
                                    class="inline-flex items-center gap-2 px-3.5 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-semibold transition cursor-pointer">
                                    <input type="checkbox" id="remove_profile_photo_checkbox" name="remove_profile_photo" value="1"
                                        onchange="toggleRemoveProfilePhoto(this)"
                                        class="rounded text-rose-600 focus:ring-rose-500">
                                    <span>Hapus Foto Profil Saat Ini</span>
                                </label>
                            </div>
                        @endif

                        <p id="profile-photo-filename" class="text-[11px] text-slate-500">
                            Format JPG, PNG, WEBP, atau GIF dengan ukuran maksimal 5 MB. Klik <strong>Simpan Pembaruan Profil</strong> setelah memilih foto.
                        </p>
                        @error('profile_photo')<p class="text-rose-500 text-xs font-medium">{{ $message }}</p>@enderror
                    </div>
                </div>
            </div>

            <!-- Section 1: Informasi Dasar -->
            <div>
                <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Informasi Akun</h4>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Nama Lengkap</label>
                        <input type="text" name="name" value="{{ old('name', $user->name) }}" required
                            class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                        @error('name')<p class="text-rose-500 text-xs mt-1.5">{{ $message }}</p>@enderror
                    </div>

                    <div>
                        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Email Perusahaan</label>
                        <input type="email" name="email" value="{{ old('email', $user->email) }}" required
                            class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                        @error('email')<p class="text-rose-500 text-xs mt-1.5">{{ $message }}</p>@enderror
                    </div>
                </div>
            </div>

            <!-- Section 2: Keamanan & Kata Sandi -->
            <div class="pt-5 border-t border-slate-100">
                <h4 class="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Keamanan Akun & Kata Sandi</h4>
                <div class="max-w-xl">
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Kata Sandi Baru (Opsional)</label>
                    <input type="password" name="password" placeholder="Kosongkan jika tidak ingin mengubah"
                        class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                    <p class="text-[11px] text-slate-400 mt-1">Minimal 6 karakter jika ingin mengganti kata sandi login.</p>
                    @error('password')<p class="text-rose-500 text-xs mt-1.5">{{ $message }}</p>@enderror
                </div>
            </div>

            <!-- Form Actions -->
            <div class="pt-6 border-t border-slate-100 flex items-center justify-end gap-3">
                <button type="submit"
                    class="px-6 py-2.5 bg-sky-600 hover:bg-sky-500 active:scale-[0.99] text-white rounded-xl text-sm font-semibold shadow-xs hover:shadow transition-all cursor-pointer">
                    Simpan Pembaruan Profil
                </button>
            </div>
        </form>
    </div>

</div>

<script>
    const originalProfilePhotoUrl = @json($user->profile_photo_url);

    function previewProfilePhoto(input) {
        const img = document.getElementById('profile-photo-preview-img');
        const initials = document.getElementById('profile-photo-preview-initials');
        const filenameEl = document.getElementById('profile-photo-filename');
        const removeCb = document.getElementById('remove_profile_photo_checkbox');

        if (input.files && input.files[0]) {
            const file = input.files[0];
            if (removeCb) removeCb.checked = false;
            const reader = new FileReader();
            reader.onload = function (e) {
                img.src = e.target.result;
                img.style.display = 'block';
                initials.style.display = 'none';
            };
            reader.readAsDataURL(file);
            filenameEl.textContent = 'Foto terpilih: ' + file.name + ' (klik Simpan Pembaruan Profil untuk menerapkan).';
        }
    }

    function toggleRemoveProfilePhoto(cb) {
        const img = document.getElementById('profile-photo-preview-img');
        const initials = document.getElementById('profile-photo-preview-initials');
        const fileInput = document.getElementById('profile_photo_input');
        const filenameEl = document.getElementById('profile-photo-filename');

        if (cb.checked) {
            if (fileInput) fileInput.value = '';
            img.style.display = 'none';
            initials.style.display = 'inline';
            filenameEl.textContent = 'Foto profil akan dihapus setelah Anda menyimpan pembaruan profil.';
        } else if (originalProfilePhotoUrl) {
            img.src = originalProfilePhotoUrl;
            img.style.display = 'block';
            initials.style.display = 'none';
            filenameEl.textContent = 'Format JPG, PNG, atau WEBP dengan ukuran maksimal 3 MB. Foto profil akan tampil di portal web dan aplikasi mobile.';
        }
    }
</script>
@endsection
