import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		proxy: {
			'/__openclaw__/webhooks': {
				target: 'http://127.0.0.1:18789',
				changeOrigin: true,
				secure: false,
			}
		}
	}
});