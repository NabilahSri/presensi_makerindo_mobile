<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UserRequest;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class UserController extends Controller
{
    public function index(Request $request): View
    {
        $search = $request->query('search');
        $perPage = in_array((int) $request->input('per_page'), [5, 10, 15, 25, 50])
            ? (int) $request->input('per_page')
            : 10;

        $users = User::with('roles')
            ->when($search, function ($query, $search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            })
            ->latest()
            ->paginate($perPage)
            ->withQueryString();

        return view('admin.users.index', compact('users', 'search'));
    }

    public function create(): View
    {
        $roles = Role::all();

        return view('admin.users.create', compact('roles'));
    }

    public function store(UserRequest $request): RedirectResponse
    {
        $validated = $request->validated();
        $roles = $validated['roles'] ?? [];
        unset($validated['roles'], $validated['profile_photo'], $validated['remove_profile_photo']);

        $validated['password'] = Hash::make($validated['password'] ?? 'password');
        $validated['can_approve_leaves'] = $request->boolean('can_approve_leaves');

        if ($request->hasFile('profile_photo')) {
            $validated['profile_photo_path'] = $request->file('profile_photo')->store('profile-photos', 'public');
        }

        $user = User::create($validated);
        $user->roles()->sync($roles);

        return redirect()->route('admin.users.index')->with('success', 'Karyawan berhasil didaftarkan.');
    }

    public function edit(User $user): View
    {
        $roles = Role::all();
        $user->load('roles');

        return view('admin.users.edit', compact('user', 'roles'));
    }

    public function update(UserRequest $request, User $user): RedirectResponse
    {
        $validated = $request->validated();
        $roles = $validated['roles'] ?? [];
        unset($validated['roles'], $validated['profile_photo'], $validated['remove_profile_photo']);

        if (! empty($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $validated['can_approve_leaves'] = $request->boolean('can_approve_leaves');

        if ($request->hasFile('profile_photo')) {
            if (! empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
                Storage::disk('public')->delete($user->profile_photo_path);
            }
            $validated['profile_photo_path'] = $request->file('profile_photo')->store('profile-photos', 'public');
        } elseif ($request->boolean('remove_profile_photo')) {
            if (! empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
                Storage::disk('public')->delete($user->profile_photo_path);
            }
            $validated['profile_photo_path'] = null;
        }

        $user->update($validated);
        $user->roles()->sync($roles);

        return redirect()->route('admin.users.index')->with('success', 'Data karyawan berhasil diperbarui.');
    }

    public function destroy(User $user): RedirectResponse
    {
        if ($user->id === auth()->id()) {
            return back()->with('error', 'Tidak dapat menghapus akun sendiri.');
        }

        if (! empty($user->profile_photo_path) && Storage::disk('public')->exists($user->profile_photo_path)) {
            Storage::disk('public')->delete($user->profile_photo_path);
        }

        $user->delete();

        return redirect()->route('admin.users.index')->with('success', 'Karyawan berhasil dihapus.');
    }
}
