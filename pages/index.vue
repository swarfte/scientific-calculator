<template>
  <div class="flex justify-center items-center min-h-screen bg-gray-900 p-4">
    <div class="flex flex-col w-full max-w-sm">
      <!-- Calculator Display -->
      <div class="bg-gray-200/90 rounded-lg p-4 mb-2 h-40 flex flex-col justify-between">
        <div class="flex justify-between">
          <div class="text-xl font-medium">
            <span class="inline-block" v-html="displayExpression" />
          </div>
        </div>

        <!-- fraction answer -->
        <div class="h-8 flex">
          <div class="flex-grow">
            <div class="text-right">
              <span v-if="!isNaN(floatResult) && fractionResult.denominator.value != 1 && displayExpression.length > 38"
                class="fraction text-xl">
                <span class="numerator">{{ fractionResult.numerator }} </span>
                <span class="denominator">{{ fractionResult.denominator }}
                </span>
              </span>
            </div>
          </div>
        </div>

        <!-- floating answer -->
        <div v-if="!isNaN(floatResult) && displayExpression.length > 38" class="text-right text-lg" if>
          = {{ floatResult }}
        </div>
      </div>

      <!-- <KeyButton :symbol="demoKey.getSymbol()" :text-color="demoKey.getTextColor() || 'text-white'"
        :background-color="demoKey.getBackgroundColor() || 'bg-gray-700'" :trigger-key="demoKey.getTriggerKey()"
        size="text-lg" :callback="demoKey.callback" :expression-symbol="demoKey.getExpressionSymbol()" /> -->

      <!-- Keyboard -->
      <div v-for="row in keyboardPanel.getKeyboardRow()" :key="row.getId()" class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in row.getKeyboardButtons()" :key="btn.getSymbol()" :symbol="btn.getSymbol()"
          :text-color="btn.getTextColor() || 'text-white'" :background-color="btn.getBackgroundColor() || 'bg-gray-700'"
          :trigger-key="btn.getTriggerKey()" size="text-lg" :callback="btn.callback"
          :expression-symbol="btn.getExpressionSymbol()" />
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { definePageMeta, Expression, Debug, Keyboard, KeyboardRow, buttons } from '#imports'
definePageMeta({
  colorMode: 'light',
})



const expression = Expression.getInstance();

const displayExpression = computed(() => {
  return expression.getHTMLExpression() // the minimum length of the expression is 38
})

const floatResult = expression.getResult()

const fractionResult = {
  numerator: expression.getNumerator(),
  denominator: expression.getDenominator()
}

const keyboardPanel = ref(Keyboard.getInstance());
keyboardPanel.value.setKeyboardRow(
  [
    new KeyboardRow(
      [
        buttons["Shift"],
        buttons["△"],
        buttons["▽"],
        buttons["◁"],
        buttons["▷"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["x/y"],
        buttons["√x"],
        buttons["aSin"],
        buttons["aCos"],
        buttons["aTan"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["x^2"],
        buttons["x^y"],
        buttons["Sin"],
        buttons["Cos"],
        buttons["Tan"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["RCL"],
        buttons["Log"],
        buttons["("],
        buttons[")"],
        buttons["S⇔D"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["7"],
        buttons["8"],
        buttons["9"],
        buttons["⌫"],
        buttons["AC"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["4"],
        buttons["5"],
        buttons["6"],
        buttons["×"],
        buttons["÷"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["1"],
        buttons["2"],
        buttons["3"],
        buttons["+"],
        buttons["-"]
      ]
    ),
    new KeyboardRow(
      [
        buttons["0"],
        buttons["."],
        buttons["Ans"],
        buttons["%"],
        buttons["="]
      ]
    ),
  ]
)
</script>

<style>
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

@keyframes blink {

  0%,
  100% {
    opacity: 1;
  }

  50% {
    opacity: 0;
  }
}

.animate-blink {
  animation: blink 1s ease-in-out infinite;
}
</style>