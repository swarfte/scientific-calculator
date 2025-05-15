<!-- KeyButton.vue -->
<template>
  <button :class="[prop.backgroundColor, prop.textColor, 'rounded-md h-12 flex items-center justify-center w-full']"
    class="boxed"
    @click="prop.callback ? prop.callback(expression, characterFactory) : defaultAction(expression, characterFactory)">
    <span :class="prop.size">{{ prop.symbol }}</span>
  </button>
</template>

<script lang="ts" setup>
import { CharacterFactory, Expression } from '#imports';

const prop = defineProps({
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
  },
  callback: {
    type: Function,
    required: false,
  }
});

const characterFactory = CharacterFactory.getInstance();
const expression = Expression.getInstance();

function defaultAction(expression: Expression, characterFactory: CharacterFactory) {
  const character = characterFactory.createCharacter(prop.symbol);
  expression.addCharacter(character);
  expression.calculate();
  console.log(`Default action for ${prop.symbol}`);
}

</script>