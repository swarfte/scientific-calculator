<template>
  <div>

  </div>
</template>

<script lang="ts" setup>
import { useTitleStore } from '~/stores/titleStore';
const { setCurrentTitle } = useTitleStore()
setCurrentTitle('Advance')

</script>

<style></style>