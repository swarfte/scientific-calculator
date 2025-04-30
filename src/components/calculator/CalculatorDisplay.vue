<!-- src/components/calculator/CalculatorDisplay.vue -->
<script setup lang="ts">
import { useCalculatorStore } from '@/stores/useCalculatorStore';
import { computed } from 'vue';

const calculator = useCalculatorStore();

const displayFraction = computed(() => {
  if (!calculator.fractionResult) return null;
  return {
    numerator: calculator.fractionResult.numerator,
    denominator: calculator.fractionResult.denominator
  };
});

const displayDecimal = computed(() => {
  if (calculator.decimalResult === null) return null;
  return calculator.decimalResult.toFixed(12).replace(/\.?0+$/, '');
});
</script>

<template>
  <div class="bg-[#d6e6e3] p-4 rounded-lg shadow-inner mb-2 relative min-h-[200px]">
    <!-- Mode Indicator -->
    <div class="absolute top-0 left-0 text-sm text-black font-medium p-2 flex space-x-4">
      <span :class="{ 'text-blue-600 font-bold': calculator.calculatorMode === 'NORM' }">NORM</span>
      <span :class="{ 'text-blue-600 font-bold': calculator.calculatorMode === 'MATH' }">MATH</span>
      <span :class="{ 'text-blue-600 font-bold': calculator.calculatorMode === 'FRAC' }">FRAC</span>
    </div>

    <!-- Input Expression -->
    <div class="text-black text-2xl font-mono mt-6 flex flex-col">
      <div class="input-line text-left" v-html="calculator.displayExpression"></div>

      <!-- Main display area showing current input or results -->
      <div class="mt-auto">
        <!-- Fraction Result -->
        <div v-if="displayFraction && calculator.isFractionMode" class="text-right">
          <div class="inline-block relative">
            <div class="text-2xl">{{ displayFraction.numerator }}</div>
            <div class="border-t border-black w-full"></div>
            <div class="text-2xl">{{ displayFraction.denominator }}</div>
          </div>
        </div>

        <!-- Decimal representation -->
        <div v-if="displayDecimal" class="text-right mt-2">
          = {{ displayDecimal }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.input-line {
  /* Add styles for rendering fractions with lines instead of slashes */
  display: inline-block;
}

/* CSS to render a proper fraction with horizontal line */
.fraction {
  display: inline-block;
  vertical-align: middle;
  margin: 0 0.2em;
}

.fraction .numerator {
  display: block;
  text-align: center;
  border-bottom: 1px solid black;
}

.fraction .denominator {
  display: block;
  text-align: center;
}
</style>