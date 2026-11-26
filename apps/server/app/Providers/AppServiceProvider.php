<?php

namespace App\Providers;

use App\Models\Setting;
use Carbon\Carbon;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Carbon::setLocale('id');

        View::composer('*', function ($view) {
            $brand = Setting::getBrandSettings();
            $version = config('app.version', ['number' => '1.0.0', 'build' => 1, 'commit' => 'local']);
            $verNumber = is_array($version) ? ($version['number'] ?? '1.0.0') : (string) $version;
            $verBuild = is_array($version) ? (int) ($version['build'] ?? 1) : 1;

            $view->with([
                'appBrandName' => $brand['name'],
                'appBrandSlogan' => $brand['slogan'],
                'appBrandLogoPath' => $brand['logo_path'],
                'appBrandLogoUrl' => $brand['logo_url'],
                'appOfficeName' => $brand['office_name'],
                'appVersion' => $verNumber,
                'appVersionBuild' => $verBuild,
                'appVersionFull' => "v{$verNumber} (Rilis {$verBuild})",
            ]);
        });
    }
}
