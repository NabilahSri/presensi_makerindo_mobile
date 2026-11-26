@extends('layouts.app')

@section('title', 'Ubah Karyawan - Presensi Makerindo')
@section('page_title', 'Perbarui Data Karyawan')

@section('content')
    <div class="w-full">
        <div class="bg-white/95 rounded-3xl border border-slate-200/90 p-6 sm:p-8 shadow-xs backdrop-blur-xs">
            <div class="border-b border-slate-100 pb-5 mb-6 flex items-center justify-between">
                <div>
                    <h2 class="text-base font-bold text-slate-900 tracking-tight">Ubah Informasi Personil</h2>
                    <p class="text-xs text-slate-500 mt-1">Mengubah data profil, status ikatan kerja, serta hak akses peran sistem.</p>
                </div>
                <span
                    class="text-xs font-mono font-bold text-sky-700 bg-sky-50 px-3 py-1 rounded-full border border-sky-200">
                    ID: {{ substr($user->id, 0, 8) }}...
                </span>
            </div>

            <form action="{{ route('admin.users.update', $user) }}" method="POST" enctype="multipart/form-data" class="space-y-6">
                @csrf
                @method('PUT')

                <!-- Foto Profil -->
                <div class="p-4 rounded-2xl bg-slate-50/70 border border-slate-200/90 flex flex-col sm:flex-row sm:items-center gap-4">
                    <div onclick="document.getElementById('edit_profile_photo').click()"
                        class="rounded-2xl bg-slate-900 text-sky-400 font-mono font-bold text-base flex items-center justify-center shrink-0 overflow-hidden border border-slate-200 cursor-pointer hover:ring-2 hover:ring-sky-500 transition"
                        style="width:68px;height:68px;" title="Klik untuk memilih foto profil baru">
                        @if ($user->profile_photo_url)
                            <img id="edit-user-photo-img" src="{{ $user->profile_photo_url }}" alt="{{ $user->name }}"
                                style="width:100%;height:100%;object-fit:cover;display:block;">
                            <span id="edit-user-photo-placeholder" style="display:none;">{{ strtoupper(substr($user->name, 0, 2)) }}</span>
                        @else
                            <img id="edit-user-photo-img" src="" alt="{{ $user->name }}"
                                style="width:100%;height:100%;object-fit:cover;display:none;">
                            <span id="edit-user-photo-placeholder">{{ strtoupper(substr($user->name, 0, 2)) }}</span>
                        @endif
                    </div>
                    <div class="flex-1 min-w-0 space-y-2">
                        <label for="edit_profile_photo" class="block text-xs font-bold text-slate-700 uppercase tracking-wider">Foto Profil Karyawan</label>
                        <input type="file" id="edit_profile_photo" name="profile_photo"
                            accept="image/*" onchange="previewEditUserPhoto(this)"
                            class="block w-full max-w-md text-xs text-slate-600 file:mr-3 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-slate-900 file:text-white hover:file:bg-slate-800 file:cursor-pointer cursor-pointer">
                        @if ($user->profile_photo_url)
                            <div>
                                <label
                                    class="inline-flex items-center gap-2 px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-semibold cursor-pointer transition">
                                    <input type="checkbox" id="edit_remove_profile_photo" name="remove_profile_photo" value="1"
                                        onchange="toggleEditRemoveUserPhoto(this)"
                                        class="rounded text-rose-600 focus:ring-rose-500">
                                    <span>Hapus Foto Profil Saat Ini</span>
                                </label>
                            </div>
                        @endif
                        <p id="edit-user-photo-name" class="text-[11px] text-slate-500">Format JPG, PNG, WEBP, atau GIF (maks. 5 MB). Klik <strong>Simpan Perubahan</strong> setelah memilih foto.</p>
                        @error('profile_photo')
                            <p class="text-rose-500 text-xs font-medium">{{ $message }}</p>
                        @enderror
                    </div>
                </div>

                <!-- Nama & Email -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Nama
                            Lengkap</label>
                        <input type="text" name="name" value="{{ old('name', $user->name) }}" required
                            class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                        @error('name')
                            <p class="text-rose-500 text-xs mt-1.5 font-medium">{{ $message }}</p>
                        @enderror
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Email
                            Perusahaan</label>
                        <input type="email" name="email" value="{{ old('email', $user->email) }}" required
                            class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                        @error('email')
                            <p class="text-rose-500 text-xs mt-1.5 font-medium">{{ $message }}</p>
                        @enderror
                    </div>
                </div>

                <!-- Password & Status Kerja -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Kata Sandi Baru
                            (Opsional)</label>
                        <input type="password" name="password" placeholder="Biarkan kosong jika tidak ingin diubah"
                            class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">Status Ikatan
                            Kerja</label>
                        <select name="employment_type" required
                            class="w-full px-4 py-2.5 bg-slate-50/70 border border-slate-300 rounded-xl text-slate-900 text-sm focus:outline-none focus:bg-white focus:border-slate-900 focus:ring-4 focus:ring-slate-900/5 transition-all">
                            <option value="KARTAP"
                                {{ old('employment_type', $user->employment_type) == 'KARTAP' ? 'selected' : '' }}>Karyawan Tetap (KARTAP)</option>
                            <option value="PKWT"
                                {{ old('employment_type', $user->employment_type) == 'PKWT' ? 'selected' : '' }}>Kontrak Kerja (PKWT)</option>
                            <option value="INTERN"
                                {{ old('employment_type', $user->employment_type) == 'INTERN' ? 'selected' : '' }}>Magang / PKL</option>
                        </select>
                    </div>
                </div>

                <!-- Roles Checklist -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2.5">Penugasan Peran
                        Sistem</label>
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
                        @php $userRoleIds = $user->roles->pluck('id')->toArray(); @endphp
                        @foreach ($roles as $role)
                            <label
                                class="flex items-start gap-3 p-3.5 rounded-2xl border border-slate-200/90 hover:border-slate-400 bg-slate-50/50 hover:bg-white transition cursor-pointer">
                                <input type="checkbox" name="roles[]" value="{{ $role->id }}"
                                    {{ in_array($role->id, old('roles', $userRoleIds)) ? 'checked' : '' }}
                                    class="mt-0.5 rounded text-sky-600 focus:ring-sky-500">
                                <div>
                                    <p class="text-xs font-bold text-slate-900">{{ $role->display_name ?? $role->name }}
                                    </p>
                                    <p class="text-[10px] text-slate-400 font-mono mt-0.5">{{ $role->name }}</p>
                                </div>
                            </label>
                        @endforeach
                    </div>
                </div>

                <!-- Approver Privilege Switch -->
                <div class="p-4 rounded-2xl bg-slate-50 border border-slate-200/90 flex items-start gap-3.5">
                    <input type="checkbox" name="can_approve_leaves" id="can_approve" value="1"
                        {{ old('can_approve_leaves', $user->can_approve_leaves) ? 'checked' : '' }}
                        class="mt-1 rounded text-sky-600 focus:ring-sky-500">
                    <label for="can_approve" class="cursor-pointer">
                        <p class="text-xs font-bold text-slate-900">Otoritas Persetujuan Cuti & Izin (Penyetuju)</p>
                        <p class="text-[11px] text-slate-500 mt-0.5 leading-relaxed">
                            Centang opsi ini jika personil berhak menyetujui atau menolak permohonan cuti dan izin anggota tim.
                        </p>
                    </label>
                </div>

                <!-- Form Actions -->
                <div class="flex items-center justify-end gap-3 pt-5 border-t border-slate-100">
                    <a href="{{ route('admin.users.index') }}"
                        class="px-5 py-2.5 rounded-xl text-sm font-semibold text-slate-600 hover:bg-slate-100 transition cursor-pointer">
                        Batal
                    </a>
                    <button type="submit"
                        class="px-6 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-sm font-semibold shadow-sm hover:shadow active:scale-[0.99] transition-all cursor-pointer">
                        Simpan Perubahan
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script>
        const originalEditUserPhotoUrl = @json($user->profile_photo_url);

        function previewEditUserPhoto(input) {
            const img = document.getElementById('edit-user-photo-img');
            const placeholder = document.getElementById('edit-user-photo-placeholder');
            const nameEl = document.getElementById('edit-user-photo-name');
            const removeCb = document.getElementById('edit_remove_profile_photo');

            if (input.files && input.files[0]) {
                const file = input.files[0];
                if (removeCb) removeCb.checked = false;
                const reader = new FileReader();
                reader.onload = function (e) {
                    img.src = e.target.result;
                    img.style.display = 'block';
                    placeholder.style.display = 'none';
                };
                reader.readAsDataURL(file);
                nameEl.textContent = 'Foto terpilih: ' + file.name + ' (klik Simpan Perubahan untuk menerapkan).';
            }
        }

        function toggleEditRemoveUserPhoto(cb) {
            const img = document.getElementById('edit-user-photo-img');
            const placeholder = document.getElementById('edit-user-photo-placeholder');
            const fileInput = document.getElementById('edit_profile_photo');
            const nameEl = document.getElementById('edit-user-photo-name');

            if (cb.checked) {
                if (fileInput) fileInput.value = '';
                img.style.display = 'none';
                placeholder.style.display = 'inline';
                nameEl.textContent = 'Foto profil akan dihapus setelah Anda menekan Simpan Perubahan.';
            } else if (originalEditUserPhotoUrl) {
                img.src = originalEditUserPhotoUrl;
                img.style.display = 'block';
                placeholder.style.display = 'none';
                nameEl.textContent = 'Format JPG, PNG, WEBP, atau GIF (maks. 5 MB).';
            }
        }
    </script>
@endsection
