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
      enabled: true,
      type: "module",
      suppressWarnings: true,
      navigateFallback: "/",
    },
    injectRegister: "auto",
    registerType: "autoUpdate",
    workbox: {
      globPatterns: ["**/*.{js,css,html,png,jpg,svg,woff2,ttf}"],
      runtimeCaching: [
        {
          urlPattern: ({ url }) => url.pathname.startsWith("/"),
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
      theme_color: "#ffffff",
      display: "standalone", // single page app
      icons: [
        // inside the public folder
        {
          src: "pwa-192x192.png",
          sizes: "192x192",
          type: "image/png",
        },
        {
          src: "pwa-512x512.png",
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
    "@pinia/nuxt",
    "pinia-plugin-persistedstate/nuxt",
    "@vueuse/nuxt",
    "@vite-pwa/nuxt",
  ],
});
