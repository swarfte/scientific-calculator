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
          <div class="text-gray-500 flex flex-col justify-center">
            <div class="flex flex-col space-y-1">
              <div class="w-1 h-1 bg-gray-500 rounded-full"></div>
              <div class="w-1 h-1 bg-gray-500 rounded-full"></div>
              <div class="w-1 h-1 bg-gray-500 rounded-full"></div>
            </div>
          </div>
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

      <!-- Top Menu Row -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-purple-700/80 text-white h-12 rounded-md flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
        <button class="bg-purple-600/80 text-white h-12 rounded-md flex items-center justify-center text-sm">
          <span class="text-white">PRO</span>
        </button>
        <button class="bg-gray-800 text-white h-12 rounded-md flex items-center justify-center text-2xl">
          <span>Σ</span>
        </button>
        <button class="bg-gray-800 text-white h-12 rounded-md flex items-center justify-center text-xl">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        </button>
        <button class="bg-gray-800 text-white h-12 rounded-md flex items-center justify-center text-xl">
          <span>%</span>
        </button>
        <button
          class="bg-purple-600/80 text-white h-12 rounded-md flex items-center justify-center text-sm font-medium">
          MORE
        </button>
      </div>

      <!-- Function Row -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-amber-500 text-black h-12 rounded-md flex items-center justify-center text-sm font-medium">
          SHIFT
        </button>
        <button
          class="bg-purple-500/80 text-white h-12 rounded-md flex items-center justify-center text-sm font-medium">
          ALPHA
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ◀
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ▶
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm font-medium">
          MODE
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm font-medium">
          2nd
        </button>
      </div>

      <!-- Additional Function Row -->
      <div class="grid grid-cols-6 gap-1 mb-1 text-xs">
        <div class="flex items-center justify-center text-amber-500">SOLVE</div>
        <div class="flex items-center justify-center text-amber-500">=</div>
        <div class="flex items-center justify-center text-amber-500">d/dx</div>
        <div class="flex items-center justify-center text-amber-500">:</div>
        <div class="flex items-center justify-center text-amber-500">x!</div>
        <div class="flex items-center justify-center text-amber-500">Σ</div>
      </div>

      <!-- Scientific Functions Row 1 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          CALC
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          ∫dx
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ▼
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ▲
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          x<sup>-1</sup>
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          Log<sub>x</sub>y
        </button>
      </div>

      <!-- Scientific Functions Row 2 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          x/y
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          √x
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          x<sup>2</sup>
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          x<sup>y</sup>
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          Log
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          Ln
        </button>
      </div>

      <!-- Scientific Functions Row 3 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          (−)
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          °'"
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          hyp
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          Sin
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          Cos
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          Tan
        </button>
      </div>

      <!-- Scientific Functions Row 4 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          RCL
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          ENG
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          (
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          )
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          S⇔D
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-sm">
          M+
        </button>
      </div>

      <!-- Number Pad Row 1 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          7
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          8
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          9
        </button>
        <button class="bg-orange-600 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ×
        </button>
        <button class="bg-orange-600 text-white h-12 rounded-md flex items-center justify-center text-xl">
          AC
        </button>
      </div>

      <!-- Number Pad Row 2 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          4
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          5
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          6
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ×
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          ÷
        </button>
      </div>

      <!-- Number Pad Row 3 -->
      <div class="grid grid-cols-6 gap-1 mb-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          1
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          2
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          3
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          +
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          −
        </button>
      </div>

      <!-- Number Pad Row 4 -->
      <div class="grid grid-cols-6 gap-1">
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          0
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          .
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          Exp
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-lg">
          Ans
        </button>
        <button class="bg-gray-700 text-white h-12 rounded-md flex items-center justify-center text-xl">
          =
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { definePageMeta } from '#imports'

definePageMeta({
  colorMode: 'light',
})
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