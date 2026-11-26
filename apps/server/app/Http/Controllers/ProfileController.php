<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class ProfileController extends Controller
{
    public function edit(): View
    {
        $user = auth()->user()->load('roles');
        return view('profile.edit', compact('user'));
    }

    public function update(Request $request): RedirectResponse
    {
        $user = auth()->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => "required|email|unique:users,email,{$user->id}",
            'password' => 'nullable|string|min:6',
            'profile_photo' => 'nullable|image|max:5120',
            'remove_profile_photo' => 'nullable|boolean',
        ], [
            'profile_photo.image' => 'Foto profil harus berupa berkas gambar yang valid (JPG, PNG, WEBP, atau GIF).',
            'profile_photo.max' => 'Ukuran foto profil maksimal 5 MB.',
        ]);

        unset($validated['profile_photo'], $validated['remove_profile_photo']);

        if (!empty($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        if ($request->hasFile('profile_photo')) {
            if (!empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
                Storage::disk('public')->delete($user->profile_photo_path);
            }
            $validated['profile_photo_path'] = $request->file('profile_photo')->store('profile-photos', 'public');
        } elseif ($request->boolean('remove_profile_photo')) {
            if (!empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
                Storage::disk('public')->delete($user->profile_photo_path);
            }
            $validated['profile_photo_path'] = null;
        }

        $user->update($validated);

        return back()->with('success', 'Profil dan informasi akun berhasil diperbarui.');
    }
}
