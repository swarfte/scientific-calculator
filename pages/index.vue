<template>
  <div class="flex justify-center items-center min-h-screen bg-gray-900 p-4">
    <div class="flex flex-col w-full max-w-sm">
      <!-- Calculator Display -->
      <div class="bg-gray-200/90 rounded-lg p-4 mb-2 h-40 flex flex-col justify-between">
        <div class="flex justify-between">
          <div class="text-2xl font-medium">
            <span class="inline-block">
              <span class="fraction">
                <span class="numerator">1</span>
                <span class="denominator">3</span>
              </span>
              +
              <span class="fraction">
                <span class="numerator">1</span>
                <span class="denominator">4</span>
              </span>
            </span>
          </div>
          <div></div>
        </div>

        <div class="h-8 flex">
          <!-- for show different result style -->
          <!-- <div class="text-gray-500 flex flex-col justify-center">
            <div class="flex flex-col space-y-1">
              <div class="w-1 h-1 bg-gray-500 rounded-full"></div>
              <div class="w-1 h-1 bg-gray-500 rounded-full"></div>
              <div class="w-1 h-1 bg-gray-500 rounded-full"></div>
            </div>
          </div> -->
          <div class="flex-grow"></div>
          <div class="text-right">
            <span class="fraction text-xl">
              <span class="numerator">7</span>
              <span class="denominator">12</span>
            </span>
          </div>
        </div>

        <div class="text-right text-lg">
          = 0.583 333 333 33
        </div>
      </div>

      <!-- Function Row -->
      <div class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton symbol="SHIFT" text-color="text-black" background-color="bg-amber-500" size="text-sm" />
        <KeyButton v-for="btn in ['△', '▽', '◁', '▷']" :key="btn" :symbol="btn" />
      </div>

      <!-- Scientific Functions Row 2 -->
      <div class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in ['x/y', '√x', 'x2', 'xy', 'Log']" :key="btn" :symbol="btn" size="text-lg" />
      </div>

      <!-- Scientific Functions Row 3 -->
      <div class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in ['(−)', '°\'', 'hyp', 'Sin', 'Cos']" :key="btn" :symbol="btn" size="text-lg" />
      </div>

      <!-- Scientific Functions Row 4 -->
      <div class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in ['RCL', 'ENG', '(', ')', 'S⇔D']" :key="btn" :symbol="btn" />
      </div>

      <!-- Number Pad Rows -->
      <div v-for="row in numPadRows" :key="row.id" class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in row.buttons" :key="btn.symbol" :symbol="btn.symbol"
          :text-color="btn.textColor || 'text-white'" :background-color="btn.bgColor || 'bg-gray-700'" size="text-lg" />
      </div>

      <!-- Number Pad Row 4 -->
      <div class="grid grid-cols-5 gap-2">
        <KeyButton v-for="btn in ['0', '.', 'Exp', 'Ans', '=']" :key="btn" :symbol="btn"
          :background-color="btn === '=' ? 'bg-green-500' : undefined" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { definePageMeta } from '#imports'

definePageMeta({
  colorMode: 'light',
})

const numPadRows = [
  {
    id: 1,
    buttons: [
      { symbol: '7' },
      { symbol: '8' },
      { symbol: '9' },
      { symbol: 'DEL', textColor: 'text-black', bgColor: 'bg-amber-500' },
      { symbol: 'AC', textColor: 'text-black', bgColor: 'bg-amber-500' },
    ],
  },
  {
    id: 2,
    buttons: [
      { symbol: '4' },
      { symbol: '5' },
      { symbol: '6' },
      { symbol: '×' },
      { symbol: '÷' },
    ],
  },
  {
    id: 3,
    buttons: [
      { symbol: '1' },
      { symbol: '2' },
      { symbol: '3' },
      { symbol: "+" },
      { symbol: '-' },
    ],
  },
]

</script>

<style scoped>
/* Custom CSS for fractions */
.fraction {
  display: inline-block;
  vertical-align: middle;
  margin: 0 0.2em;
  text-align: center;
}

.numerator,
.denominator {
  display: block;
  line-height: 1;
}

.numerator {
  border-bottom: 1px solid black;
}
</style>