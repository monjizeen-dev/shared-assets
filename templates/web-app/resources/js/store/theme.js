import { reactive } from 'vue';

const STORAGE_KEY = 'app-theme';

function isDarkMode(store) {
    if (store.mode === 'dark') {
        return true;
    }
    if (store.mode === 'light') {
        return false;
    }

    return store.systemPrefersDark;
}

function applyFromStore(store) {
    if (typeof document === 'undefined') {
        return;
    }

    document.documentElement.classList.toggle('dark', isDarkMode(store));
}

function attachSystemListener(store) {
    if (typeof window === 'undefined') {
        return;
    }

    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    store.systemPrefersDark = mediaQuery.matches;
    mediaQuery.addEventListener('change', (event) => {
        store.systemPrefersDark = event.matches;
        applyFromStore(store);
    });
}

export const theme = reactive({
    /** User preference: follow OS, or force light/dark */
    mode: 'system',
    /** Cached prefers-color-scheme; only used when mode === 'system' */
    systemPrefersDark: false,
    /** Kept for ThemeToggle disable state (no animated transition in template) */
    transitionActive: false,

    init() {
        attachSystemListener(this);
        try {
            const stored = localStorage.getItem(STORAGE_KEY);
            if (stored === 'light' || stored === 'dark' || stored === 'system') {
                this.mode = stored;
            }
        } catch {
            /* ignore quota / private mode */
        }
        applyFromStore(this);
    },

    setMode(mode) {
        this.mode = mode;
        try {
            localStorage.setItem(STORAGE_KEY, mode);
        } catch {
            /* ignore quota / private mode */
        }
        applyFromStore(this);
    },

    /** System until first click, then light ↔ dark */
    cycleMode() {
        if (this.mode === 'system') {
            this.setMode(this.effectiveDark ? 'light' : 'dark');
            return;
        }
        this.setMode(this.mode === 'light' ? 'dark' : 'light');
    },

    get effectiveDark() {
        return isDarkMode(this);
    },
});
