<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\DrinkController;
use App\Http\Controllers\Api\AuthController;

/*
|--------------------------------------------------------------------------
| PUBLIC API (TANPA LOGIN)
|--------------------------------------------------------------------------
*/
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/drinks', [DrinkController::class, 'index']);

/*
|--------------------------------------------------------------------------
| PROTECTED API (BUTUH TOKEN)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
});