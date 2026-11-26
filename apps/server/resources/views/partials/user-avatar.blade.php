@php
    $avatarSize = (int) ($size ?? 36);
    $avatarShape = $shape ?? 'rounded-xl';
    $avatarDark = (bool) ($dark ?? false);
    $avatarName = $user->name ?? 'Karyawan';
    $avatarEmail = $user->email ?? '';
    $avatarUrl = $user?->profile_photo_url;
    $avatarInitials = strtoupper(substr($avatarName, 0, 2));
@endphp

@if ($avatarUrl)
    <button type="button"
        onclick='openAttendancePhotoModal(@json($avatarUrl), @json("Foto Profil - " . $avatarName), @json($avatarEmail))'
        class="{{ $avatarShape }} overflow-hidden shrink-0 border {{ $avatarDark ? 'border-slate-700 bg-slate-900' : 'border-slate-200 bg-slate-100' }} shadow-2xs cursor-pointer hover:ring-2 hover:ring-sky-500 transition"
        style="width:{{ $avatarSize }}px;height:{{ $avatarSize }}px;padding:0;"
        title="Klik untuk memperbesar foto profil {{ $avatarName }}">
        <img src="{{ $avatarUrl }}" alt="{{ $avatarName }}" loading="lazy"
            style="width:100%;height:100%;object-fit:cover;display:block;">
    </button>
@else
    <div class="{{ $avatarShape }} {{ $avatarDark ? 'bg-slate-900 text-white border border-slate-800' : 'bg-slate-100 text-slate-700 border border-slate-200' }} font-mono font-bold text-xs flex items-center justify-center shrink-0 shadow-2xs"
        style="width:{{ $avatarSize }}px;height:{{ $avatarSize }}px;">
        {{ $avatarInitials }}
    </div>
@endif
