<script setup>
import { Button } from '@/components/ui/button';
import { Link, usePage } from '@inertiajs/vue3';
import { LogOut } from 'lucide-vue-next';
import { computed } from 'vue';

const page = usePage();
const user = computed(() => page.props.auth?.user);
const appName = computed(() => page.props.app?.name ?? '');
const logoHref = computed(() => (user.value ? route('dashboard') : route('home')));
</script>

<template>
    <div class="bg-background text-foreground min-h-screen">
        <header class="border-border border-b">
            <div class="mx-auto flex max-w-6xl items-center justify-between px-4 py-4">
                <Link :href="logoHref" class="text-lg font-semibold">{{ appName }}</Link>
                <nav class="flex items-center gap-2">
                    <Button v-if="!user" as-child>
                        <Link :href="route('login')">Sign in</Link>
                    </Button>
                    <Button v-else variant="ghost" as-child>
                        <Link :href="route('logout')" method="post" as="button">
                            <LogOut class="size-4" />
                            Sign out
                        </Link>
                    </Button>
                </nav>
            </div>
        </header>
        <main class="mx-auto max-w-6xl px-4 py-8">
            <slot />
        </main>
    </div>
</template>
