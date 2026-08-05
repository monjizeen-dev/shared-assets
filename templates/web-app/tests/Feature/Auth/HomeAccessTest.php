<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HomeAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_closed_apps_redirect_guests_to_login(): void
    {
        config(['platform.auth_model' => 'closed']);

        $this->get('/')->assertRedirect(route('login'));
    }

    public function test_open_apps_keep_public_home_page(): void
    {
        config(['platform.auth_model' => 'open']);

        $this->get('/')
            ->assertOk()
            ->assertInertia(fn ($page) => $page->component('home/HomePage'));
    }

    public function test_authenticated_users_are_sent_to_dashboard_from_home(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/')
            ->assertRedirect(route('dashboard'));
    }

    public function test_login_page_redirects_authenticated_users_to_dashboard(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get(route('login'))
            ->assertRedirect(route('dashboard'));
    }
}
