<!-- KeyButton.vue -->
<template>
  <button :class="[
    prop.backgroundColor,
    prop.textColor,
    'rounded-md h-12 flex items-center justify-center w-full transition-transform active:scale-90'
  ]" @click="handleClick()">
    <span :class="prop.size">{{ prop.symbol }}</span>
  </button>
</template>

<script lang="ts" setup>
import { CharacterFactory, Expression, Debug } from '#imports';

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
  },
  triggerKey: {
    type: String,
    default: null
  }
});

const pressed = ref(false)
const characterFactory = CharacterFactory.getInstance()
const expression = Expression.getInstance()

function handleClick(): void {
  if (prop.callback) {
    prop.callback(expression, characterFactory)
  } else {
    defaultAction(expression, characterFactory)
  }
}

function defaultAction(expression: Expression, characterFactory: CharacterFactory): void {
  const character = characterFactory.createCharacter(prop.symbol)
  expression.addCharacter(character)
  expression.calculate()
}

// Handle keyboard input
function handleKeydown(event: KeyboardEvent): void {
  // Prevent interference with input components
  if (
    event.target instanceof HTMLInputElement ||
    event.target instanceof HTMLTextAreaElement
  ) {
    return
  }

  const key = event.key.toLowerCase()

  const executeKey = prop.triggerKey ? prop.triggerKey.toLowerCase() : prop.symbol.toLowerCase()

  if (key === executeKey) {
    event.preventDefault()

    // Trigger action and animation
    handleClick()

    pressed.value = true
    setTimeout(() => {
      pressed.value = false
    }, 100) // Match transition duration
  }
}

// Lifecycle management
onMounted(() => {
  window.addEventListener('keydown', handleKeydown)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleKeydown)
})

</script>