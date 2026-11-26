<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'sqlite') {
            return;
        }

        if (Schema::hasTable('attendances')) {
            DB::table('attendances')
                ->where('method', 'RFID')
                ->update(['method' => 'FACIAL_LOCATION']);

            DB::statement('PRAGMA foreign_keys = OFF');

            try {
                DB::statement('DROP TABLE IF EXISTS `attendances_sqlite_new`');
                DB::statement(<<<'SQL'
CREATE TABLE "attendances_sqlite_new" (
    "id" varchar not null,
    "user_id" varchar not null,
    "date" date not null,
    "time_in" time,
    "time_out" time,
    "status" varchar check ("status" in ('HADIR_ON_SITE', 'WFA', 'TUGAS_LUAR', 'CUTI', 'SAKIT', 'IZIN', 'ALPHA')) not null default 'ALPHA',
    "method" varchar check ("method" in ('FACIAL_LOCATION', 'FORM')),
    "face_image_path" varchar,
    "latitude" numeric,
    "longitude" numeric,
    "is_late" tinyint(1) not null default '0',
    "overtime_hours" integer not null default '0',
    "created_at" datetime,
    "updated_at" datetime,
    "checkout_face_image_path" varchar,
    "checkout_latitude" numeric,
    "checkout_longitude" numeric,
    foreign key("user_id") references "users"("id") on delete cascade,
    primary key ("id")
)
SQL);

                DB::statement(<<<'SQL'
INSERT INTO "attendances_sqlite_new" (
    "id", "user_id", "date", "time_in", "time_out", "status", "method",
    "face_image_path", "latitude", "longitude", "is_late", "overtime_hours",
    "created_at", "updated_at", "checkout_face_image_path", "checkout_latitude", "checkout_longitude"
)
SELECT
    "id", "user_id", "date", "time_in", "time_out", "status",
    CASE WHEN "method" = 'RFID' THEN 'FACIAL_LOCATION' ELSE "method" END,
    "face_image_path", "latitude", "longitude", "is_late", "overtime_hours",
    "created_at", "updated_at", "checkout_face_image_path", "checkout_latitude", "checkout_longitude"
FROM "attendances"
SQL);

                DB::statement('DROP TABLE "attendances"');
                DB::statement('ALTER TABLE "attendances_sqlite_new" RENAME TO "attendances"');
            } finally {
                DB::statement('PRAGMA foreign_keys = ON');
            }
        }

        if (Schema::hasTable('leave_requests')) {
            DB::statement('PRAGMA foreign_keys = OFF');

            try {
                DB::statement('DROP TABLE IF EXISTS `leave_requests_sqlite_new`');
                DB::statement(<<<'SQL'
CREATE TABLE "leave_requests_sqlite_new" (
    "id" varchar not null,
    "user_id" varchar not null,
    "type" varchar check ("type" in ('SAKIT', 'IZIN', 'WFA', 'CUTI', 'TUGAS_LUAR')) not null,
    "start_date" date not null,
    "end_date" date not null,
    "reason" text not null,
    "attachment_path" varchar,
    "status" varchar check ("status" in ('PENDING', 'APPROVED', 'REJECTED')) not null default 'PENDING',
    "approved_by" varchar,
    "rejection_reason" text,
    "created_at" datetime,
    "updated_at" datetime,
    foreign key("user_id") references "users"("id") on delete cascade,
    foreign key("approved_by") references "users"("id") on delete set null,
    primary key ("id")
)
SQL);

                DB::statement(<<<'SQL'
INSERT INTO "leave_requests_sqlite_new" (
    "id", "user_id", "type", "start_date", "end_date", "reason",
    "attachment_path", "status", "approved_by", "rejection_reason", "created_at", "updated_at"
)
SELECT
    "id", "user_id", "type", "start_date", "end_date", "reason",
    "attachment_path", "status", "approved_by", "rejection_reason", "created_at", "updated_at"
FROM "leave_requests"
SQL);

                DB::statement('DROP TABLE "leave_requests"');
                DB::statement('ALTER TABLE "leave_requests_sqlite_new" RENAME TO "leave_requests"');
            } finally {
                DB::statement('PRAGMA foreign_keys = ON');
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (DB::getDriverName() !== 'sqlite') {
            return;
        }

        if (Schema::hasTable('attendances')) {
            DB::table('attendances')
                ->whereIn('status', ['CUTI', 'TUGAS_LUAR'])
                ->update(['status' => 'IZIN']);

            DB::statement('PRAGMA foreign_keys = OFF');

            try {
                DB::statement('DROP TABLE IF EXISTS `attendances_sqlite_old`');
                DB::statement(<<<'SQL'
CREATE TABLE "attendances_sqlite_old" (
    "id" varchar not null,
    "user_id" varchar not null,
    "date" date not null,
    "time_in" time,
    "time_out" time,
    "status" varchar check ("status" in ('HADIR_ON_SITE', 'WFA', 'SAKIT', 'IZIN', 'ALPHA')) not null default 'ALPHA',
    "method" varchar check ("method" in ('RFID', 'FACIAL_LOCATION', 'FORM')),
    "face_image_path" varchar,
    "latitude" numeric,
    "longitude" numeric,
    "is_late" tinyint(1) not null default '0',
    "overtime_hours" integer not null default '0',
    "created_at" datetime,
    "updated_at" datetime,
    "checkout_face_image_path" varchar,
    "checkout_latitude" numeric,
    "checkout_longitude" numeric,
    foreign key("user_id") references "users"("id") on delete cascade,
    primary key ("id")
)
SQL);
                DB::statement(<<<'SQL'
INSERT INTO "attendances_sqlite_old" SELECT * FROM "attendances"
SQL);
                DB::statement('DROP TABLE "attendances"');
                DB::statement('ALTER TABLE "attendances_sqlite_old" RENAME TO "attendances"');
            } finally {
                DB::statement('PRAGMA foreign_keys = ON');
            }
        }

        if (Schema::hasTable('leave_requests')) {
            DB::table('leave_requests')
                ->whereIn('type', ['CUTI', 'TUGAS_LUAR'])
                ->update(['type' => 'IZIN']);

            DB::statement('PRAGMA foreign_keys = OFF');

            try {
                DB::statement('DROP TABLE IF EXISTS `leave_requests_sqlite_old`');
                DB::statement(<<<'SQL'
CREATE TABLE "leave_requests_sqlite_old" (
    "id" varchar not null,
    "user_id" varchar not null,
    "type" varchar check ("type" in ('SAKIT', 'IZIN', 'WFA')) not null,
    "start_date" date not null,
    "end_date" date not null,
    "reason" text not null,
    "attachment_path" varchar,
    "status" varchar check ("status" in ('PENDING', 'APPROVED', 'REJECTED')) not null default 'PENDING',
    "approved_by" varchar,
    "rejection_reason" text,
    "created_at" datetime,
    "updated_at" datetime,
    foreign key("user_id") references "users"("id") on delete cascade,
    foreign key("approved_by") references "users"("id") on delete set null,
    primary key ("id")
)
SQL);
                DB::statement(<<<'SQL'
INSERT INTO "leave_requests_sqlite_old" SELECT * FROM "leave_requests"
SQL);
                DB::statement('DROP TABLE "leave_requests"');
                DB::statement('ALTER TABLE "leave_requests_sqlite_old" RENAME TO "leave_requests"');
            } finally {
                DB::statement('PRAGMA foreign_keys = ON');
            }
        }
    }
};
