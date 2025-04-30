<!-- src/components/calculator/CalculatorKeypad.vue -->
<script setup lang="ts">
import { useCalculatorStore } from '@/stores/useCalculatorStore';

const calculator = useCalculatorStore();

// Helper function to toggle modes
function toggleMode() {
  const modes: Array<'NORM' | 'MATH' | 'FRAC'> = ['NORM', 'MATH', 'FRAC'];
  const currentIndex = modes.indexOf(calculator.calculatorMode);
  const nextIndex = (currentIndex + 1) % modes.length;
  calculator.changeMode(modes[nextIndex]);
}

// Toggle modifier keys
function toggleShift() {
  calculator.shiftActive = !calculator.shiftActive;
  calculator.alphaActive = false;
  calculator.secondActive = false;
}

function toggleAlpha() {
  calculator.alphaActive = !calculator.alphaActive;
  calculator.shiftActive = false;
  calculator.secondActive = false;
}

function toggleSecond() {
  calculator.secondActive = !calculator.secondActive;
  calculator.shiftActive = false;
  calculator.alphaActive = false;
}
</script>

<template>
  <div class="calculator-keypad">
    <!-- Top Menu Bar -->
    <div class="grid grid-cols-6 gap-1 mb-2">
      <button class="menu-btn bg-[#444]">
        <span class="text-white">☰</span>
      </button>
      <button class="menu-btn bg-purple-600 col-span-1">
        <span class="text-white">PRO</span>
      </button>
      <button class="menu-btn bg-[#333]">
        <span class="text-white">Σ</span>
      </button>
      <button class="menu-btn bg-[#333]">
        <span class="text-white">⚙</span>
      </button>
      <button class="menu-btn bg-[#333]">
        <span class="text-white">∡</span>
      </button>
      <button class="menu-btn bg-[#333]">
        <span class="text-white">DEG</span>
      </button>
    </div>

    <!-- Mode Selectors & Function Keys -->
    <div class="grid grid-cols-6 gap-1 mb-2">
      <button @click="toggleShift"
        :class="{ 'bg-yellow-500': calculator.shiftActive, 'bg-[#333]': !calculator.shiftActive }"
        class="btn text-yellow-500 hover:bg-yellow-600">
        SHIFT
      </button>
      <button @click="toggleAlpha"
        :class="{ 'bg-indigo-500': calculator.alphaActive, 'bg-[#333]': !calculator.alphaActive }"
        class="btn text-indigo-400 hover:bg-indigo-600">
        ALPHA
      </button>
      <button class="btn bg-[#333] text-white">
        ◀
      </button>
      <button class="btn bg-[#333] text-white">
        ▶
      </button>
      <button @click="toggleMode" class="btn bg-[#333] text-white">
        MODE
      </button>
      <button @click="toggleSecond"
        :class="{ 'bg-gray-500': calculator.secondActive, 'bg-[#333]': !calculator.secondActive }"
        class="btn text-white hover:bg-gray-600">
        2nd
      </button>
    </div>

    <!-- Scientific Function Keys - Row 1 -->
    <div class="grid grid-cols-6 gap-1 mb-2">
      <button class="btn bg-[#333] text-white">
        CALC
      </button>
      <button class="btn bg-[#333] text-white">
        ∫dx
      </button>
      <button class="btn bg-[#333] text-white">
        ▼
      </button>
      <button class="btn bg-[#333] text-white">
        ▲
      </button>
      <button class="btn bg-[#333] text-white">
        x⁻¹
      </button>
      <button class="btn bg-[#333] text-white">
        Log<sub>x</sub>y
      </button>
    </div>

    <!-- Scientific Function Keys - Row 2 -->
    <div class="grid grid-cols-6 gap-1 mb-2">
      <button class="btn bg-[#333] text-white">
        x/y
      </button>
      <button class="btn bg-[#333] text-white">
        √x
      </button>
      <button class="btn bg-[#333] text-white">
        x²
      </button>
      <button class="btn bg-[#333] text-white">
        xʸ
      </button>
      <button class="btn bg-[#333] text-white">
        Log
      </button>
      <button class="btn bg-[#333] text-white">
        Ln
      </button>
    </div>

    <!-- Scientific Function Keys - Row 3 -->
    <div class="grid grid-cols-6 gap-1 mb-2">
      <button class="btn bg-[#333] text-white">
        (-)
      </button>
      <button class="btn bg-[#333] text-white">
        °'"
      </button>
      <button class="btn bg-[#333] text-white">
        hyp
      </button>
      <button class="btn bg-[#333] text-white">
        Sin
      </button>
      <button class="btn bg-[#333] text-white">
        Cos
      </button>
      <button class="btn bg-[#333] text-white">
        Tan
      </button>
    </div>

    <!-- Scientific Function Keys - Row 4 -->
    <div class="grid grid-cols-6 gap-1 mb-2">
      <button class="btn bg-[#333] text-white">
        RCL
      </button>
      <button class="btn bg-[#333] text-white">
        ENG
      </button>
      <button class="btn bg-[#333] text-white">
        (
      </button>
      <button class="btn bg-[#333] text-white">
        )
      </button>
      <button class="btn bg-[#333] text-white">
        S⇔D
      </button>
      <button class="btn bg-[#333] text-white">
        M+
      </button>
    </div>

    <!-- Number Pad - Row 1 -->
    <div class="grid grid-cols-5 gap-1 mb-2">
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('7')">
        7
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('8')">
        8
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('9')">
        9
      </button>
      <button class="num-btn bg-orange-500 text-black" @click="calculator.clearAll()">
        DEL
      </button>
      <button class="num-btn bg-orange-500 text-black" @click="calculator.clearAll()">
        AC
      </button>
    </div>

    <!-- Number Pad - Row 2 -->
    <div class="grid grid-cols-5 gap-1 mb-2">
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('4')">
        4
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('5')">
        5
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('6')">
        6
      </button>
      <button class="num-btn bg-gray-600 text-white" @click="calculator.performOperation('×')">
        ×
      </button>
      <button class="num-btn bg-gray-600 text-white" @click="calculator.performOperation('÷')">
        ÷
      </button>
    </div>

    <!-- Number Pad - Row 3 -->
    <div class="grid grid-cols-5 gap-1 mb-2">
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('1')">
        1
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('2')">
        2
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('3')">
        3
      </button>
      <button class="num-btn bg-gray-600 text-white" @click="calculator.performOperation('+')">
        +
      </button>
      <button class="num-btn bg-gray-600 text-white" @click="calculator.performOperation('-')">
        −
      </button>
    </div>

    <!-- Number Pad - Row 4 -->
    <div class="grid grid-cols-5 gap-1">
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDigit('0')">
        0
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputDot()">
        .
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.inputFraction()">
        a/b
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.performOperation('Ans')">
        Ans
      </button>
      <button class="num-btn bg-gray-800 text-white" @click="calculator.calculateResult()">
        =
      </button>
    </div>
  </div>
</template>

<style scoped>
.calculator-keypad {
  @reference bg-black rounded-lg p-2;
}

.btn {
  @reference rounded py-2 px-1 text-xs font-bold hover:opacity-80 transition-opacity;
}

.menu-btn {
  @reference rounded py-2 text-xs font-medium hover:opacity-80 transition-opacity;
}

.num-btn {
  @reference rounded py-3 text-xl font-medium hover:opacity-80 transition-opacity;
}
</style>