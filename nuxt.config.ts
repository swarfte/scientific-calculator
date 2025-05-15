// https://nuxt.com/docs/api/configuration/nuxt-config
import { fileURLToPath, URL } from "url";

export default defineNuxtConfig({
  compatibilityDate: "2024-11-01",
  devtools: { enabled: true },
  pwa: {},
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
