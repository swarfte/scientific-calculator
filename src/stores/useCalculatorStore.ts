// src/stores/useCalculatorStore.ts
import { defineStore } from "pinia";
import { ref, computed } from "vue";
import { Fraction } from "@/composables/math/Fraction";

type CalculatorMode = "NORM" | "MATH" | "FRAC";
type DisplayMode = "decimal" | "fraction" | "both";

export const useCalculatorStore = defineStore("calculator", () => {
  // Display state
  const inputExpression = ref<string>("");
  const currentInput = ref<string>("");
  const result = ref<string>("");
  const decimalResult = ref<number | null>(null);
  const fractionResult = ref<Fraction | null>(null);

  // Mode settings
  const calculatorMode = ref<CalculatorMode>("NORM");
  const displayMode = ref<DisplayMode>("both");
  const isFractionMode = ref<boolean>(false);
  const hasDecimal = ref<boolean>(false);

  // UI state
  const shiftActive = ref<boolean>(false);
  const alphaActive = ref<boolean>(false);
  const secondActive = ref<boolean>(false);

  // Current operation being built
  const firstOperand = ref<Fraction | null>(null);
  const secondOperand = ref<Fraction | null>(null);
  const operator = ref<string | null>(null);
  const waitingForOperand = ref<boolean>(false);

  // Computed display values
  const displayExpression = computed(() => {
    return inputExpression.value;
  });

  const displayResult = computed(() => {
    if (calculatorMode.value === "FRAC" && fractionResult.value) {
      return fractionResult.value.toString();
    } else if (decimalResult.value !== null) {
      return decimalResult.value.toString();
    }
    return "";
  });

  // Actions - Number Input
  function inputDigit(digit: string): void {
    if (waitingForOperand.value) {
      currentInput.value = digit;
      waitingForOperand.value = false;
    } else {
      if (currentInput.value === "0" && digit !== ".") {
        currentInput.value = digit;
      } else {
        currentInput.value += digit;
      }
    }
    updateInputExpression();
  }

  function inputDot(): void {
    if (waitingForOperand.value) {
      currentInput.value = "0.";
      waitingForOperand.value = false;
    } else if (!currentInput.value.includes(".")) {
      currentInput.value += ".";
    }
    hasDecimal.value = true;
    updateInputExpression();
  }

  function inputFraction(): void {
    if (!currentInput.value.includes("/")) {
      currentInput.value += "/";
    }
  }

  // Actions - Operations
  function performOperation(op: string): void {
    const inputValue = parseCurrentInput();

    if (firstOperand.value === null) {
      firstOperand.value = inputValue;
      operator.value = op;
      waitingForOperand.value = true;
      updateInputExpression();
      return;
    }

    if (waitingForOperand.value) {
      operator.value = op;
      updateInputExpression();
      return;
    }

    // Perform the pending operation
    if (operator.value) {
      secondOperand.value = inputValue;
      calculateResult();
      operator.value = op;
      waitingForOperand.value = true;
      updateInputExpression();
    }
  }

  function calculateResult(): void {
    if (!firstOperand.value || !operator.value) return;

    const secondValue = (
      waitingForOperand.value ? firstOperand.value : parseCurrentInput()
    ) as Fraction;

    let resultFraction: Fraction;

    switch (operator.value) {
      case "+":
        resultFraction = firstOperand.value.add(secondValue);
        break;
      case "-":
        resultFraction = firstOperand.value.subtract(secondValue);
        break;
      case "×":
        resultFraction = firstOperand.value.multiply(secondValue);
        break;
      case "÷":
        resultFraction = firstOperand.value.divide(secondValue);
        break;
      default:
        return;
    }

    // Update results
    fractionResult.value = resultFraction;
    decimalResult.value = resultFraction.decimalValue;

    // Update for next operation
    firstOperand.value = resultFraction;
    secondOperand.value = null;
    currentInput.value = "";
    waitingForOperand.value = true;
    updateInputExpression(true);
  }

  // Helper methods
  function parseCurrentInput(): Fraction {
    if (!currentInput.value || currentInput.value === "") {
      return new Fraction(0, 1);
    }

    if (currentInput.value.includes("/")) {
      const [numeratorStr, denominatorStr] = currentInput.value.split("/");
      const numerator = parseInt(numeratorStr);
      const denominator = parseInt(denominatorStr) || 1;
      return new Fraction(numerator, denominator);
    }

    const value = parseFloat(currentInput.value);
    return hasDecimal.value
      ? Fraction.fromDecimal(value)
      : new Fraction(value, 1);
  }

  function updateInputExpression(showResult: boolean = false): void {
    let expression = "";

    if (firstOperand.value) {
      if (calculatorMode.value === "FRAC") {
        expression += firstOperand.value.toString();
      } else {
        expression += firstOperand.value.decimalValue.toString();
      }
    }

    if (operator.value) {
      expression += ` ${operator.value} `;
    }

    if (currentInput.value && !waitingForOperand.value) {
      expression += currentInput.value;
    }

    inputExpression.value = expression;

    if (showResult && fractionResult.value) {
      result.value = fractionResult.value.toString();
    }
  }

  function clearAll(): void {
    inputExpression.value = "";
    currentInput.value = "";
    result.value = "";
    decimalResult.value = null;
    fractionResult.value = null;
    firstOperand.value = null;
    secondOperand.value = null;
    operator.value = null;
    waitingForOperand.value = false;
    hasDecimal.value = false;
  }

  function changeMode(mode: CalculatorMode): void {
    calculatorMode.value = mode;
    isFractionMode.value = mode === "FRAC";
  }

  return {
    // State
    inputExpression,
    currentInput,
    result,
    decimalResult,
    fractionResult,
    calculatorMode,
    displayMode,
    isFractionMode,
    shiftActive,
    alphaActive,
    secondActive,

    // Computed
    displayExpression,
    displayResult,

    // Actions
    inputDigit,
    inputDot,
    inputFraction,
    performOperation,
    calculateResult,
    clearAll,
    changeMode,
  };
});
