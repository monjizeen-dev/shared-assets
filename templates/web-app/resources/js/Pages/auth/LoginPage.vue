<script setup>
import ThemeToggle from '@/components/ThemeToggle.vue';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { usePage } from '@inertiajs/vue3';
import { computed } from 'vue';

const page = usePage();
const appName = computed(() => page.props.app?.name ?? '');
const flashError = computed(() => page.props.flash?.error ?? null);
</script>

<template>
    <div class="bg-background text-foreground relative flex min-h-screen items-center justify-center p-4">
        <div class="absolute top-4 end-4">
            <ThemeToggle />
        </div>
        <Card class="w-full max-w-md shadow-sm">
            <CardHeader class="space-y-3 text-center">
                <CardTitle class="text-3xl font-semibold tracking-tight">{{ appName }}</CardTitle>
                <CardDescription class="text-base">Sign in with your Google account</CardDescription>
            </CardHeader>
            <CardContent class="space-y-4">
                <p
                    v-if="flashError"
                    class="border-destructive/40 bg-destructive/10 text-destructive rounded-md border px-3 py-2 text-sm"
                >
                    {{ flashError }}
                </p>

                <Button as-child variant="outline" size="lg" class="w-full gap-3">
                    <a :href="route('login.google')">
                        <svg class="size-5 shrink-0" viewBox="0 0 24 24" aria-hidden="true">
                            <path
                                fill="#4285F4"
                                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" />
                            <path
                                fill="#34A853"
                                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                            <path
                                fill="#FBBC05"
                                d="M5.84 14.09A6.96 6.96 0 0 1 5.49 12c0-.73.13-1.43.35-2.09V7.07H2.18A11 11 0 0 0 1 12c0 1.78.43 3.45 1.18 4.93l3.66-2.84z" />
                            <path
                                fill="#EA4335"
                                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84C6.71 7.31 9.14 5.38 12 5.38z" />
                        </svg>
                        <span>Continue with Google</span>
                    </a>
                </Button>
            </CardContent>
        </Card>
    </div>
</template>
