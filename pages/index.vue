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
      <!-- Keyboard -->
      <div v-for="row in numPadRows" :key="row.id" class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in row.buttons" :key="btn.symbol" :symbol="btn.symbol"
          :text-color="btn.textColor || 'text-white'" :background-color="btn.backgroundColor || 'bg-gray-700'"
          :trigger-key="btn.triggerKey" size="text-lg" :callback="btn.callback"
          :expression-symbol="btn.expressionSymbol" />
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { definePageMeta, Expression, Debug, type KeyboardRow, mathjs } from '#imports'
const expression = Expression.getInstance();

const displayExpression = computed(() => {
  return expression.getHTMLExpression() // the minimum length of the expression is 38
})

const floatResult = expression.getResult()

const fractionResult = {
  numerator: expression.getNumerator(),
  denominator: expression.getDenominator()
}

definePageMeta({
  colorMode: 'light',
})

const numPadRows: KeyboardRow[] = [
  {
    id: 7,
    buttons: [
      {
        symbol: 'AI', backgroundColor: 'bg-green-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => {
          Debug.info("asin(0.5) = ", mathjs.evaluate('asin(0.5)'));
        }
      },
      { symbol: '△', textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.moveIndexLocationToStart() } },
      { symbol: '▽', textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.moveIndexLocationToEnd() } },
      { symbol: '◁', textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.moveIndexLocationToLeft() } },
      { symbol: '▷', textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.moveIndexLocationToRight() } },
    ],
  },
  {
    id: 6,
    buttons: [
      { symbol: 'x/y' },
      { symbol: '√x' },
      { symbol: 'aSin', expressionSymbol: 'asin(' },
      { symbol: 'aCos', expressionSymbol: 'acos(' },
      { symbol: 'aTan', expressionSymbol: 'atan(' },
    ],
  },
  {
    id: 5,
    buttons: [
      { symbol: 'x^2' },
      { symbol: 'x^y' },
      { symbol: 'Sin', triggerKey: 's', expressionSymbol: 'sin(' },
      { symbol: 'Cos', triggerKey: 'c', expressionSymbol: 'cos(' },
      { symbol: 'Tan', triggerKey: 't', expressionSymbol: 'tan(' },
    ],
  },
  {
    id: 4,
    buttons: [
      { symbol: 'RCL' },
      { symbol: 'Log' },
      { symbol: '(' },
      { symbol: ')' },
      { symbol: 'S⇔D' },
    ],
  },
  {
    id: 3,
    buttons: [
      { symbol: '7' },
      { symbol: '8' },
      { symbol: '9' },
      {
        symbol: '⌫', triggerKey: "backspace", textColor: 'text-black', backgroundColor: 'bg-amber-500'
        , callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.removeLeftSideCharacter(); }
      },
      {
        symbol: 'AC', triggerKey: "\\", textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.clear(); }
      },
    ],
  },
  {
    id: 2,
    buttons: [
      { symbol: '4' },
      { symbol: '5' },
      { symbol: '6' },
      { symbol: '×', triggerKey: '*' },
      { symbol: '÷', triggerKey: '/' },
    ],
  },
  {
    id: 1,
    buttons: [
      { symbol: '1' },
      { symbol: '2' },
      { symbol: '3' },
      { symbol: "+" },
      { symbol: '-' },
    ],
  },
  {
    id: 0,
    buttons: [
      { symbol: '0' },
      { symbol: '.' },
      { symbol: 'Ans', triggerKey: "tab" },
      { symbol: '%' },
      {
        symbol: '=', triggerKey: "Enter", textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, characterFactory: CharacterFactory) => {
          expression.savePreviousAnswer();
          const previousAnswer = expression.getPreviousAnswer();
          const character = characterFactory.createCharacter(String(previousAnswer.value));
          expression.addCharacter(character);
          // Debug.info('Current Expression:', expression.getExpression());
          expression.moveIndexLocationToEnd();
          expression.calculate(); // for display the answer value
        }
      },
    ]
  }
]

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