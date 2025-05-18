<!-- KeyButton.vue -->
<template>
  <button :class="[
    prop.backgroundColor,
    prop.textColor,
    'rounded-md h-12 flex items-center justify-center w-full transition duration-100',
    { 'scale-90 opacity-75': pressed }
  ]" @click="handleInteraction()">
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

function performAction(): void {
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

function handleInteraction(): void {
  // 1. Perform the button's core action
  performAction();

  // 2. Trigger the visual effect manually using the 'pressed' ref
  //    Only set if not already in the pressed state (e.g., holding down key or rapid clicks)
  if (!pressed.value) {
    pressed.value = true;
    setTimeout(() => {
      pressed.value = false;
    }, 100); // Match the transition duration added in classes (duration-100)
  }
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

    handleInteraction()
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