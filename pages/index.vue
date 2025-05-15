<template>
  <div class="flex justify-center items-center min-h-screen bg-gray-900 p-4">
    <div class="flex flex-col w-full max-w-sm">
      <!-- Calculator Display -->
      <div class="bg-gray-200/90 rounded-lg p-4 mb-2 h-40 flex flex-col justify-between">
        <div class="flex justify-between">
          <div class="text-xl font-medium">
            <span class="inline-block" v-html="displayExpression">

            </span>
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
        <KeyButton v-for="btn in ['(−)', '°\'', 'Sin', 'Cos', 'Tan']" :key="btn" :symbol="btn" size="text-lg" />
      </div>

      <!-- Scientific Functions Row 4 -->
      <div class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in ['RCL', 'ENG', '(', ')', 'S⇔D']" :key="btn" :symbol="btn" />
      </div>

      <!-- Number Pad Rows -->
      <div v-for="row in numPadRows" :key="row.id" class="grid grid-cols-5 gap-2 mb-2">
        <KeyButton v-for="btn in row.buttons" :key="btn.symbol" :symbol="btn.symbol"
          :text-color="btn.textColor || 'text-white'" :background-color="btn.bgColor || 'bg-gray-700'" size="text-lg"
          :callback="(btn as any).callback" />
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { definePageMeta, Expression } from '#imports'
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

const numPadRows = [
  {
    id: 3,
    buttons: [
      { symbol: '7' },
      { symbol: '8' },
      { symbol: '9' },
      {
        symbol: 'DEL', textColor: 'text-black', bgColor: 'bg-amber-500'
        , callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.removeLastCharacter(); }
      },
      {
        symbol: 'AC', textColor: 'text-black', bgColor: 'bg-amber-500', callback: (expression: Expression, _characterFactory: CharacterFactory) => { expression.clear(); }
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
      { symbol: 'Ans', bgColor: "bg-green-500" },
      { symbol: '%' },
      {
        symbol: '=', textColor: 'text-black', bgColor: 'bg-amber-500', callback: (expression: Expression, characterFactory: CharacterFactory) => {
          expression.savePreviousAnswer();
          const previousAnswer = expression.getPreviousAnswer();
          console.log('Previous Answer:', previousAnswer);
          const character = characterFactory.createCharacter(String(previousAnswer.value));
          expression.addCharacter(character);
        }
      },
    ]
  }
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