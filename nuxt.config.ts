// https://nuxt.com/docs/api/configuration/nuxt-config
import { fileURLToPath, URL } from "url";

export default defineNuxtConfig({
  compatibilityDate: "2024-11-01",
  devtools: { enabled: true },
  css: ["~/assets/css/main.css"],
  alias: {
    "@": fileURLToPath(new URL("./", import.meta.url)),
    "@components": fileURLToPath(new URL("./components", import.meta.url)),
    "@assets": fileURLToPath(new URL("./assets", import.meta.url)),
    "@stores": fileURLToPath(new URL("./stores", import.meta.url)),
    "@public": fileURLToPath(new URL("./public", import.meta.url)),
    "@layouts": fileURLToPath(new URL("./layouts", import.meta.url)),
    "@composables": fileURLToPath(new URL("./composables", import.meta.url)),
    "@pages": fileURLToPath(new URL("./pages", import.meta.url)),
  },
  pwa: {
    devOptions: {
      // only enable in production mode
      enabled: false,
      type: "module",
      suppressWarnings: false,
      navigateFallback: "/",
    },
    injectRegister: "auto",
    registerType: "autoUpdate",
    workbox: {
      navigateFallback: "/",
      globPatterns: ["**/*.{js,css,html,png,jpg,svg,woff2,ttf}"],
      runtimeCaching: [
        {
          urlPattern: /^.*$/, // 匹配所有 URL
          handler: "CacheFirst", // offlineFirst
          options: {
            cacheName: "main-cache",
            expiration: {
              maxEntries: 100, // maximum number of entries in the cache
              maxAgeSeconds: 60 * 60 * 24 * 30, // 30 days
            },
          },
        },
      ],
      skipWaiting: true,
      clientsClaim: true,
      cleanupOutdatedCaches: true,
    },
    manifest: {
      id: "Smart Calculator",
      name: "Smart Calculator",
      short_name: "CalcS",
      description: "A smart calculator that include AI features",
      theme_color: "#F8F8F8",
      background_color: "#F8F8F8",
      display: "standalone",
      screenshots: [
        {
          src: "screenshot/desktop_2560x1251.png",
          sizes: "2560x1251",
          type: "image/png",
          form_factor: "wide",
          label: "Application",
        },
        {
          src: "screenshot/mobile_709x1087.png",
          sizes: "709x1087",
          type: "image/png",
          form_factor: "narrow",
          label: "Application",
        },
      ],
      icons: [
        // inside the public folder
        {
          src: "icons/icon_48x48.png",
          sizes: "48x48",
          type: "image/png",
        },
        {
          src: "icons/icon_72x72.png",
          sizes: "72x72",
          type: "image/png",
        },
        {
          src: "icons/icon_96x96.png",
          sizes: "96x96",
          type: "image/png",
        },
        {
          src: "icons/icon_144x144.png",
          sizes: "144x144",
          type: "image/png",
        },
        {
          src: "icons/icon_192x192.png",
          sizes: "192x192",
          type: "image/png",
        },
        {
          src: "icons/icon_512x512.png",
          sizes: "512x512",
          type: "image/png",
        },
      ],
    },
  },
  modules: [
    "@nuxt/eslint",
    "@nuxt/fonts",
    "@nuxt/icon",
    "@nuxt/scripts",
    "@nuxt/ui",
    "@vueuse/nuxt",
    "@vite-pwa/nuxt",
  ],
});
