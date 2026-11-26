<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use DatabaseTransactions;

    public function test_authenticated_user_can_view_profile_page(): void
    {
        $user = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($user)->get(route('profile.edit'));

        $response->assertOk();
        $response->assertSee('Profil Pengguna & Pengaturan Akun');
        $response->assertSee($user->name);
    }

    public function test_authenticated_user_can_update_profile_and_password(): void
    {
        $user = User::where('email', 'admin@test.com')->first();

        $response = $this->actingAs($user)->put(route('profile.update'), [
            'name' => 'Super Admin Updated',
            'email' => 'admin@test.com',
            'password' => 'newpassword123',
        ]);

        $response->assertRedirect();
        $user->refresh();

        $this->assertEquals('Super Admin Updated', $user->name);
        $this->assertTrue(Hash::check('newpassword123', $user->password));
    }

    public function test_guest_cannot_access_profile_page(): void
    {
        $response = $this->get(route('profile.edit'));
        $response->assertRedirect(route('login'));
    }
}
