<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/test', function () {
    try {
        DB::connection()->getPdo();

        return 'DB connected';
    } catch (\Exception $e) {
        $db_connection = env('DB_CONNECTION');
        $db_database = env('DB_DATABASE');
        $db_host = env('DB_HOST');
        $db_port = env('DB_PORT');
        $db_username = env('DB_USERNAME');
        $db_password = env('DB_PASSWORD');
        return "DB disconnected: {$e->getMessage()}, DB_CONNECTION={$db_connection}&DB_DATABASE={$db_database}&DB_HOST={$db_host}&DB_PORT={$db_port}&DB_USERNAME=${db_username}&DB_PASSWORD={$db_password}";
    }
});
