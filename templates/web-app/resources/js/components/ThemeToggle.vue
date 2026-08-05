<script setup>
import { Button } from '@/components/ui/button';
import { theme } from '@/store/theme.js';
import { Moon, Sun } from 'lucide-vue-next';
import { computed } from 'vue';

const props = defineProps({
    /** Optional i18n for labelTheme, themeLight, themeDark, themeSystem */
    t: { type: Function, default: null },
});

const selectedMode = computed(() => {
    if (theme.mode === 'system') {
        return theme.effectiveDark ? 'dark' : 'light';
    }

    return theme.mode;
});

const toggleAriaLabel = computed(() => {
    if (props.t) {
        const appearance = props.t(selectedMode.value === 'light' ? 'themeLight' : 'themeDark');
        if (theme.mode === 'system') {
            return `${props.t('labelTheme')}: ${props.t('themeSystem')} (${appearance})`;
        }

        return `${props.t('labelTheme')}: ${appearance}`;
    }

    if (theme.mode === 'system') {
        return `Theme follows device (${theme.effectiveDark ? 'dark' : 'light'}). Click to choose a saved theme.`;
    }

    return `Theme: ${theme.mode}. Click to switch.`;
});
</script>

<template>
    <Button
        variant="ghostHeaderIcon"
        size="icon"
        class="h-9 w-9"
        type="button"
        data-slot="theme-toggle"
        :aria-label="toggleAriaLabel"
        :disabled="theme.transitionActive"
        @click="theme.cycleMode()"
    >
        <Sun v-if="selectedMode === 'light'" class="h-4 w-4" aria-hidden="true" />
        <Moon v-else class="h-4 w-4" aria-hidden="true" />
    </Button>
</template>
