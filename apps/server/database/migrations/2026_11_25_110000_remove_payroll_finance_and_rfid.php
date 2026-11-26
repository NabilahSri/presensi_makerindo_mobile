<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Hapus tabel penggajian, insentif proyek, dan perangkat RFID/IoT
        Schema::dropIfExists('payrolls');
        Schema::dropIfExists('project_incentives');
        Schema::dropIfExists('devices');

        // 2. Hapus kolom RFID, gaji pokok, dan rekening bank dari tabel users
        if (Schema::hasTable('users')) {
            if (Schema::hasColumn('users', 'rfid_uid')) {
                try {
                    Schema::table('users', function (Blueprint $table) {
                        $table->dropUnique(['rfid_uid']);
                    });
                } catch (\Throwable) {
                    // Index sudah tidak ada atau ditangani otomatis saat dropColumn
                }
            }

            $userDropCols = array_values(array_filter([
                'rfid_uid',
                'basic_salary',
                'bank_name',
                'bank_account_number',
                'bank_account_holder',
            ], fn (string $col) => Schema::hasColumn('users', $col)));

            if (!empty($userDropCols)) {
                Schema::table('users', function (Blueprint $table) use ($userDropCols) {
                    $table->dropColumn($userDropCols);
                });
            }
        }

        // 3. Hapus kolom nominal denda uang pada tabel sanksi
        if (Schema::hasTable('sanction_rules') && Schema::hasColumn('sanction_rules', 'default_deduction_amount')) {
            Schema::table('sanction_rules', function (Blueprint $table) {
                $table->dropColumn('default_deduction_amount');
            });
        }

        if (Schema::hasTable('employee_sanctions') && Schema::hasColumn('employee_sanctions', 'deduction_amount')) {
            Schema::table('employee_sanctions', function (Blueprint $table) {
                $table->dropColumn('deduction_amount');
            });
        }

        // 4. Konversi metode presensi RFID menjadi FACIAL_LOCATION (GPS & Foto)
        if (Schema::hasTable('attendances')) {
            DB::table('attendances')
                ->where('method', 'RFID')
                ->update(['method' => 'FACIAL_LOCATION']);

            $driver = DB::getDriverName();
            if (in_array($driver, ['mysql', 'mariadb'], true)) {
                DB::statement(
                    "ALTER TABLE `attendances` MODIFY COLUMN `method` ENUM('FACIAL_LOCATION','FORM') NULL"
                );
            }
        }

        // 5. Bersihkan pengaturan penggajian / potongan gaji & perbarui slogan default
        if (Schema::hasTable('settings')) {
            DB::table('settings')
                ->whereIn('key', ['wfa_deduction_kartap_pct', 'wfa_deduction_pkwt_pct', 'payday_date'])
                ->delete();

            DB::table('settings')
                ->where('key', 'app_slogan')
                ->where('value', 'like', '%Penggajian%')
                ->update(['value' => 'Sistem Presensi GPS & Foto Makerindo']);
        }

        // 6. Hapus aturan sanksi khusus RFID
        if (Schema::hasTable('sanction_rules')) {
            DB::table('sanction_rules')->where('code', 'RFID-01')->delete();
        }

        // 7. Hapus role finance & akun bawaan finance jika ada
        if (Schema::hasTable('roles')) {
            $financeRoleId = DB::table('roles')->where('name', 'finance')->value('id');
            if ($financeRoleId) {
                if (Schema::hasTable('role_users')) {
                    DB::table('role_users')->where('role_id', $financeRoleId)->delete();
                }
                DB::table('roles')->where('id', $financeRoleId)->delete();
            }
        }

        if (Schema::hasTable('users')) {
            DB::table('users')->where('email', 'finance@test.com')->delete();
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (!Schema::hasColumn('users', 'rfid_uid')) {
                    $table->string('rfid_uid')->unique()->nullable()->after('password');
                }
                if (!Schema::hasColumn('users', 'basic_salary')) {
                    $table->decimal('basic_salary', 12, 2)->default(0)->after('employment_type');
                }
                if (!Schema::hasColumn('users', 'bank_name')) {
                    $table->string('bank_name')->nullable()->after('can_approve_leaves');
                }
                if (!Schema::hasColumn('users', 'bank_account_number')) {
                    $table->string('bank_account_number')->nullable()->after('bank_name');
                }
                if (!Schema::hasColumn('users', 'bank_account_holder')) {
                    $table->string('bank_account_holder')->nullable()->after('bank_account_number');
                }
            });
        }

        if (Schema::hasTable('sanction_rules') && !Schema::hasColumn('sanction_rules', 'default_deduction_amount')) {
            Schema::table('sanction_rules', function (Blueprint $table) {
                $table->decimal('default_deduction_amount', 12, 2)->default(0)->after('default_level');
            });
        }

        if (Schema::hasTable('employee_sanctions') && !Schema::hasColumn('employee_sanctions', 'deduction_amount')) {
            Schema::table('employee_sanctions', function (Blueprint $table) {
                $table->decimal('deduction_amount', 12, 2)->default(0)->after('occurrence_count');
            });
        }

        if (Schema::hasTable('attendances')) {
            $driver = DB::getDriverName();
            if (in_array($driver, ['mysql', 'mariadb'], true)) {
                DB::statement(
                    "ALTER TABLE `attendances` MODIFY COLUMN `method` ENUM('RFID','FACIAL_LOCATION','FORM') NULL"
                );
            }
        }
    }
};
