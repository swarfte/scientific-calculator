<!-- src/views/Home.vue -->
<script setup lang="ts">
import CalculatorDisplay from '@/components/calculator/CalculatorDisplay.vue';
import CalculatorKeypad from '@/components/calculator/CalculatorKeypad.vue';
import { useCalculatorStore } from '@/stores/useCalculatorStore';

const calculatorStore = useCalculatorStore();
</script>

<template>
  <div class="min-h-screen bg-black flex flex-col p-4">
    <!-- Calculator -->
    <div class="calculator-container">
      <CalculatorDisplay />
      <CalculatorKeypad />
    </div>
  </div>
</template>

<style scoped>
.calculator-container {
  @reference max-w-md mx-auto w-full;
}
</style>