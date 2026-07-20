<template>
  <v-layout>
    <v-app-bar app :elevation="3" rounded color="blue">
      <v-app-bar-nav-icon @click.stop="drawer = !drawer" />
      <v-app-bar-title>{{ title }}</v-app-bar-title>
    </v-app-bar>

    <v-navigation-drawer floating v-model="drawer" temporary>
      <v-list>
        <v-list-item link v-for="option in options" :key="option.title">
          <v-row>
            <v-col cols="auto">
              <v-icon>{{ option.icon }}</v-icon>
            </v-col>
            <v-col>
              <v-list-item-title @click="navigateTo(`/${option.title}`)">{{ option.title }}</v-list-item-title>
            </v-col>
          </v-row>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <slot />
  </v-layout>
</template>

<script lang="ts" setup>
import { storeToRefs } from 'pinia'
import { useTitleStore } from '~/stores/titleStore'

const titleStore = useTitleStore()
const { currentTitle } = storeToRefs(titleStore)
const drawer = ref(false)
const options = titleStore.getOptions()
const title = currentTitle
</script>

<style></style>