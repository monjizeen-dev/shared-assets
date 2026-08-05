import './bootstrap';
import { createApp, h } from 'vue';
import { createInertiaApp } from '@inertiajs/vue3';
import route from './lib/route.js';
import { theme } from './store/theme.js';

window.route = route;

createInertiaApp({
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.vue');
        return pages[`./Pages/${name}.vue`]();
    },
    setup({ el, App, props, plugin }) {
        theme.init();
        const app = createApp({ render: () => h(App, props) });
        app.config.globalProperties.route = route;
        app.use(plugin).mount(el);
    },
});
