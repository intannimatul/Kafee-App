<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Drink;

class DrinkController extends Controller
{
    public function index()
    {
        return response()->json(Drink::all());
    }
}
