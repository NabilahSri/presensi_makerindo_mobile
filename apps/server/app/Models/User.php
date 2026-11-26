<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Guarded;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;

#[Guarded([])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, HasUuids;

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'role_users')->withTimestamps();
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class);
    }

    public function dailyReports(): HasMany
    {
        return $this->hasMany(DailyReport::class);
    }

    public function leaveRequests(): HasMany
    {
        return $this->hasMany(LeaveRequest::class);
    }

    public function sanctions(): HasMany
    {
        return $this->hasMany(EmployeeSanction::class);
    }

    public function tokens(): MorphMany
    {
        return $this->morphMany(PersonalAccessToken::class, 'tokenable');
    }

    public function createToken(string $name = 'flutter-mobile-app', array $abilities = ['*']): object
    {
        $plainTextToken = Str::random(40);

        $token = $this->tokens()->create([
            'name' => $name,
            'token' => hash('sha256', $plainTextToken),
            'abilities' => $abilities,
        ]);

        return (object) [
            'accessToken' => $token,
            'plainTextToken' => $token->id . '|' . $plainTextToken,
        ];
    }

    public function hasRole(string $roleName): bool
    {
        return $this->roles->contains('name', $roleName);
    }

    public function canAccessWebPortal(): bool
    {
        $this->loadMissing('roles');

        return $this->hasRole('super_admin')
            || $this->hasRole('ceo');
    }

    public function canAccessMobileApp(): bool
    {
        $this->loadMissing('roles');

        return $this->hasRole('karyawan') || $this->hasRole('intern');
    }

    public function isAttendanceRequired(): bool
    {
        return !$this->roles->contains('is_attendance_required', false);
    }
    public function getProfilePhotoUrlAttribute(): ?string
    {
        if (empty($this->profile_photo_path)) {
            return null;
        }

        return '/storage/' . ltrim($this->profile_photo_path, '/');
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
