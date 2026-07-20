import { defineStore } from "pinia";
import { ref } from "vue";

export const useTitleStore = defineStore("title", () => {
  const options = ref([
    { title: "simple", icon: "mdi-home" },
    { title: "advance", icon: "mdi-calculator" },
    { title: "matrix", icon: "mdi-matrix" },
  ] as Title[]);

  const currentTitle = ref("simple");

  function setCurrentTitle(title: string): void {
    currentTitle.value = title;
  }

  function getCurrentTitle(): string {
    return currentTitle.value;
  }

  function getOptions(): Title[] {
    return options.value;
  }

  return { currentTitle, setCurrentTitle, getCurrentTitle, getOptions };
});
