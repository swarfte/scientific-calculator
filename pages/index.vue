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
              <span v-if="floatResult && Number(floatResult) / Number(fractionResult.numerator.value) !== 1"
                class="fraction text-xl">
                <span class="numerator">{{ fractionResult.numerator }} </span>
                <span class="denominator">{{ fractionResult.denominator }}
                </span>
              </span>
            </div>
          </div>
        </div>

        <!-- floating answer -->
        <div v-if="floatResult" class="text-right text-lg" if>
          = {{ floatResult }}
        </div>
      </div>
      <!-- Keyboard -->
      <div v-for="row in numPadRows" :key="row.id" class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in row.buttons" :key="btn.symbol" :symbol="btn.symbol"
          :text-color="btn.textColor || 'text-white'" :background-color="btn.backgroundColor || 'bg-gray-700'"
          size="text-lg" :callback="btn.callback" />
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { definePageMeta, Expression, Debug, type KeyboardRow } from '#imports'
const expression = Expression.getInstance();


const displayExpression = computed(() => {
  return expression.getHTMLExpression()
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
      { symbol: 'AI', backgroundColor: 'bg-green-500' },
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
      { symbol: 'x^2' },
      { symbol: 'x^y' },
      { symbol: 'Log' },
    ],
  },
  {
    id: 5,
    buttons: [
      { symbol: '(−)' },
      { symbol: '°\'' },
      { symbol: 'Sin' },
      { symbol: 'Cos' },
      { symbol: 'Tan' },
    ],
  },
  {
    id: 4,
    buttons: [
      { symbol: 'RCL' },
      { symbol: 'ENG' },
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
        symbol: '⌫', textColor: 'text-black', backgroundColor: 'bg-amber-500'
        , callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.removeLeftSideCharacter(); }
      },
      {
        symbol: 'AC', textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.clear(); }
      },
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
      { symbol: 'Ans' },
      { symbol: '%' },
      {
        symbol: '=', textColor: 'text-black', backgroundColor: 'bg-amber-500', callback: (expression: Expression, characterFactory: CharacterFactory) => {
          expression.savePreviousAnswer();
          const character = characterFactory.createCharacter("Ans");
          expression.addCharacter(character);
          // Debug.info('Current Expression:', expression.getExpression());
          expression.moveIndexLocationToEnd();
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