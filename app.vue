<template>
  <UApp>
    <NuxtPage />
  </UApp>
</template>

<script setup lang="ts">
import { useRegisterSW } from 'virtual:pwa-register/vue'

if (import.meta.client) {
  const { updateServiceWorker } = useRegisterSW()
  updateServiceWorker()
}

// import { createPinia } from 'pinia'
// import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
// const pinia = createPinia()
// pinia.use(piniaPluginPersistedstate)
</script>