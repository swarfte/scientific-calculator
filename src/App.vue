<!-- src/App.vue -->
<script setup lang="ts">
import { RouterView } from 'vue-router';
</script>

<template>
  <div class="app-container">
    <RouterView />
  </div>
</template>

<style>
body {
  @reference bg-black m-0 p-0;
  font-family: 'Roboto', sans-serif;
}

.app-container {
  @reference max-w-md mx-auto;
}
</style>