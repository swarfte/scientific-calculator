<!-- KeyButton.vue -->
<template>
  <button :class="[backgroundColor, textColor, 'rounded-md h-12 flex items-center justify-center w-full']" class="boxed"
    @click="$emit('click')">
    <span :class="size">{{ symbol }}</span>
  </button>
</template>

<script setup>
defineProps({
  symbol: {
    type: String,
    required: true
  },
  textColor: {
    type: String,
    default: 'text-white'
  },
  backgroundColor: {
    type: String,
    default: 'bg-gray-700'
  },
  size: {
    type: String,
    default: ''
  }
});
</script>