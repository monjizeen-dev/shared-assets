<?php

namespace App\Http\Middleware;

use App\Models\User;
use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    /** @return array<string, mixed> */
    public function share(Request $request): array
    {
        $user = $request->user();
        $userModel = $user instanceof User ? $user : null;

        return array_merge(parent::share($request), [
            'app' => [
                'name' => config('app.name'),
            ],
            'flash' => [
                'status' => fn () => $request->session()->get('status'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'csrf_token' => csrf_token(),
            'auth' => [
                'user' => $userModel ? [
                    'id' => $userModel->id,
                    'username' => $userModel->username,
                    'name' => $userModel->resolvedDisplayName(),
                    'email' => $userModel->email,
                    'global_role' => $userModel->global_role,
                    'is_admin' => $userModel->isAdmin(),
                    'photo_url' => $userModel->avatar_url,
                ] : null,
            ],
        ]);
    }
}
