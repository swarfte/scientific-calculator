import { Expression } from "#imports";

export const useCalculatorStore = defineStore("calculator", () => {
  const expression = ref<Expression>(Expression.getInstance());
  return {
    expression,
  };
});
