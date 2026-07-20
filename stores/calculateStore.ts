import { defineStore } from "pinia";
import { create, all, type MathJsInstance } from "mathjs";

export const useCalculateStore = defineStore("calculate", () => {
  const config = {
    epsilon: 1e-12,
    precision: 128,
  };

  const math = create(all, config);

  const answer = ref(null as number | null);

  function setAnswer(value: number | null): void {
    answer.value = value;
  }

  function getAnswer(): number {
    return answer.value as number;
  }

  function getMath(): MathJsInstance {
    return math;
  }

  function filterExpression(expression: string): string {
    if (answer.value !== null) {
      expression = expression.replace(
        "ans",
        (answer.value as number).toString()
      );
    } else {
      expression = expression.replace("ans", "0");
    }
    return expression;
  }

  function calculate(expression: string): string {
    const parser = math.parser();
    expression = filterExpression(expression);
    const result = parser.evaluate(expression);
    return math.format(result, { precision: 14 });
  }

  return {
    config,
    math,
    answer,
    setAnswer,
    getAnswer,
    getMath,
    filterExpression,
    calculate,
  };
});
