<template>
  <UApp>
    <NuxtPage />
  </UApp>
</template>

<script setup lang="ts">

import { createPinia } from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)
</script>