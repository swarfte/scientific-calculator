<template>
  <v-container class="h-screen pt-10 w-md-50 " fluid>
    <v-row class="h-40" no-gutters>
    </v-row>
    <v-row no-gutters class="h-20">
      <v-col cols="12">
        <v-text-field v-model="userInput" class="inputField" variant="underlined" dense readonly>
        </v-text-field>
      </v-col>
      <v-col cols="12">
        <v-text-field v-model="output" class="outputField" variant="underlined" dense readonly>
        </v-text-field>
      </v-col>
    </v-row>
    <div class="h-40 py-5">
      <v-row v-for="row in simpleKeyboard" :key="row" no-gutters>
        <v-col v-for="key in row" :key="key" cols="3" class="pa-1">
          <v-btn rounded="pill" reverse="true" size="x-large" :key="key" @click="handleUserInput(key)"
            :color="key === '=' ? 'success' : 'primary'" :class="key === 'AC' ? 'bg-red' : ''" block :text="key"
            :disabled="key === 'ans' && answer === null">
          </v-btn>
        </v-col>
      </v-row>
    </div>
  </v-container>
</template>

<script lang="ts" setup>
import { useTitleStore } from '~/stores/titleStore';
import { useCalculateStore } from '~/stores/calculateStore';
import { storeToRefs } from 'pinia';
import { useKeyboardStore, useSimpleKeyboard } from '~/stores/keyboardStore';


const { answer } = storeToRefs(useCalculateStore())
const userInput = ref('')
const output = ref('')
const { setCurrentTitle } = useTitleStore()
const keyboardStore = useKeyboardStore()
const simpleKeyboard = useSimpleKeyboard().keyboard

setCurrentTitle('Simple')

const handleUserInput = (key: string) => {
  const result = keyboardStore.handleClick(userInput, output, key)
}


watch(userInput, async (newInput) => {
  if (userInput.value !== "") {
    keyboardStore.showPreviewExpression(userInput, output)
  }
})

</script>


<style scoped>
.v-text-field>>>input {
  font-size: 2em;
  font-weight: 100;
  text-align: right;
}

.h-40 {
  height: 40%;
}

.h-20 {
  height: 20%;
}

.outputField {
  color: blue;
}
</style>