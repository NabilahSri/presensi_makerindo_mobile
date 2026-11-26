<?php

namespace App\Http\Requests\Admin;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

class UserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $user = $this->route('user');
        $userId = $user instanceof User ? $user->id : $user;

        return [
            'name' => 'required|string|max:255',
            'email' => "required|email|unique:users,email,{$userId}",
            'password' => 'nullable|string|min:6',
            'employment_type' => 'required|in:KARTAP,PKWT,INTERN',
            'can_approve_leaves' => 'boolean',
            'profile_photo' => 'nullable|image|max:5120',
            'remove_profile_photo' => 'nullable|boolean',
            'roles' => 'required|array',
            'roles.*' => 'exists:roles,id',
        ];
    }

    public function messages(): array
    {
        return [
            'profile_photo.image' => 'Foto profil harus berupa berkas gambar yang valid (JPG, PNG, WEBP, atau GIF).',
            'profile_photo.max' => 'Ukuran foto profil maksimal 5 MB.',
            'roles.required' => 'Minimal satu peran akses sistem wajib dipilih.',
        ];
    }
}
