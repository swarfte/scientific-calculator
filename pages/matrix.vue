<template>
  <div>
    <h1>Matrix</h1>
  </div>
</template>

<script lang="ts" setup>
import { useTitleStore } from '~/stores/titleStore';
const { setCurrentTitle } = useTitleStore()
setCurrentTitle('Matrix')
</script>

<style></style>