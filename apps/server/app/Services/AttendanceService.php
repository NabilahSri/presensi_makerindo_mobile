<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Setting;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Validation\ValidationException;

class AttendanceService
{
    /**
     * Hitung jarak antara dua koordinat latitude/longitude menggunakan rumus Haversine (hasil dalam meter).
     */
    public function calculateDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000; // Radius bumi dalam meter

        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(
            pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)
        ));

        return round($angle * $earthRadius, 2);
    }

    /**
     * Ambil koordinat acuan kantor dan radius geofence dari Setting.
     */
    public function getOfficeSettings(): array
    {
        return [
            'name' => Setting::getValue('office_name', 'Kantor PT Makerindo Prima Solusi'),
            'address' => Setting::getValue('office_address', 'Kantor PT Makerindo Prima Solusi, Bandung'),
            'latitude' => (float) Setting::getValue('office_latitude', -6.20880000),
            'longitude' => (float) Setting::getValue('office_longitude', 106.84560000),
            'radius' => (int) Setting::getValue('office_radius_meters', 100),
        ];
    }

    /**
     * Ambil pengaturan jam masuk, jam pulang, dan toleransi secara dinamis dari tabel settings.
     */
    public function getWorkScheduleSettings(): array
    {
        return [
            'work_start_time' => $this->normalizeTime(Setting::getValue('work_start_time', '08:00'), '08:00'),
            'work_end_time' => $this->normalizeTime(Setting::getValue('work_end_time', '17:00'), '17:00'),
            'late_tolerance_minutes' => (int) Setting::getValue('late_tolerance_minutes', 15),
            'overtime_tolerance_minutes' => (int) Setting::getValue('overtime_tolerance_minutes', 30),
        ];
    }

    private function normalizeTime(?string $value, string $fallback): string
    {
        $clean = trim((string) $value);
        if (preg_match('/^([01]\d|2[0-3]):([0-5]\d)/', $clean, $matches)) {
            return $matches[1].':'.$matches[2];
        }

        return $fallback;
    }

    public function isLateAt(Carbon $timestamp): bool
    {
        $schedule = $this->getWorkScheduleSettings();
        $standardIn = Carbon::parse($timestamp->toDateString().' '.$schedule['work_start_time'].':00');
        $lateCutoff = $standardIn->copy()->addMinutes($schedule['late_tolerance_minutes']);

        return $timestamp->greaterThan($lateCutoff);
    }

    public function calculateLateMinutes(?string $timeIn, ?string $baseDate = null): int
    {
        if (empty($timeIn)) {
            return 0;
        }

        $dateStr = $baseDate ? Carbon::parse($baseDate)->toDateString() : now()->toDateString();
        $normalizedIn = strlen(trim($timeIn)) === 5 ? trim($timeIn).':00' : trim($timeIn);
        $checkIn = Carbon::parse($dateStr.' '.$normalizedIn);

        if (! $this->isLateAt($checkIn)) {
            return 0;
        }

        $schedule = $this->getWorkScheduleSettings();
        $standardIn = Carbon::parse($dateStr.' '.$schedule['work_start_time'].':00');

        return max(0, (int) $standardIn->diffInMinutes($checkIn));
    }

    public function calculateOvertimeHours(Carbon $timestamp, ?string $baseDate = null): int
    {
        $schedule = $this->getWorkScheduleSettings();
        $dateStr = $baseDate ? Carbon::parse($baseDate)->toDateString() : $timestamp->toDateString();
        $standardOut = Carbon::parse($dateStr.' '.$schedule['work_end_time'].':00');
        $overtimeThreshold = $standardOut->copy()->addMinutes($schedule['overtime_tolerance_minutes']);

        if ($timestamp->lessThan($overtimeThreshold)) {
            return 0;
        }

        return max(0, (int) floor($standardOut->diffInMinutes($timestamp) / 60));
    }

    /**
     * Catat presensi berbasis lokasi GPS & Foto:
     * - Magang: presensi harian via GPS & Foto.
     * - Karyawan WFA / Tugas Luar: via GPS & Foto (bebas radius).
     * - Karyawan On-Site: via GPS & Foto dengan validasi radius kantor.
     *
     * @param  string  $presenceType  ('ON_SITE', 'WFA', 'TUGAS_LUAR', 'INTERN_MOBILE', 'AUTO')
     *
     * @throws ValidationException
     */
    public function recordLocationAttendance(
        User $user,
        float $latitude,
        float $longitude,
        string $presenceType = 'AUTO',
        ?string $notes = null,
        ?Carbon $timestamp = null
    ): array {
        $now = $timestamp ? $timestamp->copy() : now();
        $today = $now->toDateString();
        $timeString = $now->format('H:i:s');

        $office = $this->getOfficeSettings();
        $distance = $this->calculateDistance($latitude, $longitude, $office['latitude'], $office['longitude']);
        $isWithinRadius = ($distance <= $office['radius']);

        $isIntern = ($user->employment_type === 'INTERN');

        // Penentuan Status Kehadiran (HADIR_ON_SITE, WFA, atau TUGAS_LUAR)
        $determinedStatus = 'HADIR_ON_SITE';

        if ($presenceType === 'TUGAS_LUAR') {
            $determinedStatus = 'TUGAS_LUAR';
        } elseif ($isIntern) {
            // Anak magang presensi menggunakan location
            if ($presenceType === 'WFA') {
                $determinedStatus = 'WFA';
            } elseif ($presenceType === 'INTERN_MOBILE') {
                // Presensi harian magang via kamera & GPS tanpa pembatasan radius
                $determinedStatus = 'HADIR_ON_SITE';
            } elseif ($presenceType === 'ON_SITE') {
                if (! $isWithinRadius) {
                    throw ValidationException::withMessages([
                        'location' => "Presensi Kantor ditolak: Anda terdeteksi berada di luar area kantor ({$distance} meter dari kantor, batas radius {$office['radius']} meter). Silakan lakukan presensi saat tiba di kantor atau pilih WFA.",
                    ]);
                }
                $determinedStatus = 'HADIR_ON_SITE';
            } else {
                // Mode AUTO
                $determinedStatus = $isWithinRadius ? 'HADIR_ON_SITE' : 'WFA';
            }
        } else {
            // Karyawan (KARTAP / PKWT)
            if ($presenceType === 'WFA') {
                $determinedStatus = 'WFA';
            } elseif ($presenceType === 'ON_SITE') {
                // Karyawan hadir langsung di kantor (validasi radius GPS kantor)
                if (! $isWithinRadius) {
                    throw ValidationException::withMessages([
                        'location' => "Presensi Kantor ditolak: Posisi Anda berada di luar radius kantor ({$distance} meter dari kantor, batas toleransi {$office['radius']} meter). Pastikan Anda berada di area kantor atau pilih opsi WFA jika bekerja dari luar kantor.",
                    ]);
                }
                $determinedStatus = 'HADIR_ON_SITE';
            } else {
                // Mode AUTO
                if ($isWithinRadius) {
                    $determinedStatus = 'HADIR_ON_SITE';
                } else {
                    $determinedStatus = 'WFA';
                }
            }
        }

        // Cek record kehadiran hari ini
        $attendance = Attendance::where('user_id', $user->id)
            ->whereDate('date', $today)
            ->first();

        if ($attendance && ! $attendance->time_in && in_array($attendance->status, ['CUTI', 'SAKIT', 'IZIN'], true)) {
            throw ValidationException::withMessages([
                'attendance' => "Pengguna tercatat sedang {$attendance->status} pada tanggal {$today} sehingga tidak dapat melakukan presensi masuk.",
            ]);
        }

        if (! $attendance || ! $attendance->time_in) {
            // --- PROSES PRESENSI MASUK ---
            $isLate = $this->isLateAt($now);

            $attendance = Attendance::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'date' => $today,
                ],
                [
                    'time_in' => $timeString,
                    'status' => $determinedStatus,
                    'method' => 'FACIAL_LOCATION',
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                    'is_late' => $isLate,
                    'overtime_hours' => 0,
                ]
            );

            $typeLabel = $determinedStatus === 'TUGAS_LUAR'
                ? 'Tugas Luar'
                : ($isIntern ? 'Magang' : ($determinedStatus === 'HADIR_ON_SITE' ? 'Karyawan On-Site (GPS & Foto)' : 'Karyawan WFA'));
            $radiusLabel = $determinedStatus === 'TUGAS_LUAR'
                ? 'Tugas Luar'
                : ($isWithinRadius ? 'Dalam Radius' : 'Luar Radius / WFA');
            $message = "Presensi Masuk {$typeLabel} berhasil dicatat pada {$timeString} WIB. Jarak ke kantor: {$distance}m ({$radiusLabel}).";

            return [
                'status' => 'success',
                'action' => 'check_in',
                'attendance' => $attendance,
                'distance' => $distance,
                'is_within_radius' => $isWithinRadius,
                'message' => $message,
            ];
        }

        if ($attendance->time_out === null) {
            // --- PROSES PRESENSI PULANG ---
            $overtimeHours = $this->calculateOvertimeHours($now);

            $attendance->update([
                'time_out' => $timeString,
                'overtime_hours' => $overtimeHours,
            ]);

            $message = "Presensi Pulang berhasil dicatat pada {$timeString} WIB.".($overtimeHours > 0 ? " Lembur dihitung: {$overtimeHours} jam." : '');

            return [
                'status' => 'success',
                'action' => 'check_out',
                'attendance' => $attendance,
                'distance' => $distance,
                'is_within_radius' => $isWithinRadius,
                'message' => $message,
            ];
        }

        // Sudah pernah check-in dan check-out hari ini
        throw ValidationException::withMessages([
            'attendance' => "Anda sudah menyelesaikan presensi masuk ({$attendance->time_in}) dan pulang ({$attendance->time_out}) untuk hari ini ({$today}).",
        ]);
    }
}
