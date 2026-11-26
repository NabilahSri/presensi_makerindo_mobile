<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $driver = DB::getDriverName();

        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            DB::statement(
                "ALTER TABLE `attendances` MODIFY COLUMN `status` ENUM('HADIR_ON_SITE','WFA','TUGAS_LUAR','CUTI','SAKIT','IZIN','ALPHA') NOT NULL DEFAULT 'ALPHA'"
            );

            DB::statement(
                "ALTER TABLE `leave_requests` MODIFY COLUMN `type` ENUM('SAKIT','IZIN','WFA','CUTI','TUGAS_LUAR') NOT NULL"
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $driver = DB::getDriverName();

        if (in_array($driver, ['mysql', 'mariadb'], true)) {
            DB::statement("UPDATE `attendances` SET `status` = 'IZIN' WHERE `status` IN ('CUTI','TUGAS_LUAR')");
            DB::statement("UPDATE `leave_requests` SET `type` = 'IZIN' WHERE `type` IN ('CUTI','TUGAS_LUAR')");

            DB::statement(
                "ALTER TABLE `attendances` MODIFY COLUMN `status` ENUM('HADIR_ON_SITE','WFA','SAKIT','IZIN','ALPHA') NOT NULL DEFAULT 'ALPHA'"
            );

            DB::statement(
                "ALTER TABLE `leave_requests` MODIFY COLUMN `type` ENUM('SAKIT','IZIN','WFA') NOT NULL"
            );
        }
    }
};
