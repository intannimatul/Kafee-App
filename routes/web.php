<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\DrinkController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/api/drinks', [DrinkController::class, 'index']);
