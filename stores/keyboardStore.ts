import { defineStore } from "pinia";
import {
  type NumeralKey,
  type OperatorKey,
  type FunctionKey,
  type SpecialKey,
} from "~/composables/model";
import { useCalculateStore } from "./calculateStore";

export const useKeyboardStore = defineStore("keyboard", () => {
  const calculateStore = useCalculateStore();
  const { setAnswer, calculate } = calculateStore;
  const numeralKeys = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    ".",
  ].map((key: string): NumeralKey => ({ key, type: "normal" }));

  const operatorKeys = ["+", "-", "*", "/", "%"].map(
    (key: string): OperatorKey => ({ key, type: "operator" })
  );

  const functionKeys = ["(", ")", "sqrt", "log", "ln", "exp"].map(
    (key: string): FunctionKey => ({ key, type: "function" })
  );

  const specialKeys = [
    {
      key: "AC",
      type: "special",
      trigger: (
        inputExpress: Ref<string>,
        outputExpress: Ref<string>,
        key: string
      ) => {
        if (inputExpress.value !== "") {
          inputExpress.value = "";
        } else {
          outputExpress.value = "";
          setAnswer(null);
        }
      },
    },
    {
      key: "del",
      type: "special",
      trigger: (express: Ref<string>) => {
        // check if the previous is not a number or operator symbol
        if (!checkNumeralOrOperator(express.value[express.value.length - 1])) {
          // delete the previous word
          let wordLength = 1;
          while (
            !checkNumeralOrOperator(
              express.value[express.value.length - wordLength]
            ) &&
            wordLength < express.value.length
          ) {
            wordLength++;
          }
          express.value = express.value.slice(
            0,
            express.value.length - wordLength
          );
        } else {
          express.value = express.value.slice(0, express.value.length - 1);
        }
      },
    },
    {
      key: "ans",
      type: "special",
      trigger: (express: Ref<string>) => {
        express.value += "ans";
      },
    },
    {
      key: "=",
      type: "special",
      trigger: (
        inputExpress: Ref<string>,
        outputExpress: Ref<string>,
        key: string
      ) => {
        try {
          // if the input value not include "ans", then calculate the expression
          if (!inputExpress.value.includes("ans")) {
            outputExpress.value = calculate(inputExpress.value);
          }
          setAnswer(Number(outputExpress.value));
          inputExpress.value = "ans";
        } catch (e) {
          console.error(e);
          outputExpress.value = "error";
        }
      },
    },
  ] as SpecialKey[];
  function checkNumeralOrOperator(symbol: string): boolean {
    return (
      numeralKeys.map((k) => k.key).includes(symbol) ||
      operatorKeys.map((k) => k.key).includes(symbol)
    );
  }

  function checkKeyType(key: string): string {
    if (numeralKeys.map((k) => k.key).includes(key)) {
      return "normal";
    }
    if (operatorKeys.map((k) => k.key).includes(key)) {
      return "operator";
    }
    if (functionKeys.map((k) => k.key).includes(key)) {
      return "function";
    }
    if (specialKeys.map((k) => k.key).includes(key)) {
      return "special";
    }
    throw new Error("unknown key type");
  }

  function handleNumeralKey(
    inputExpression: Ref<string>,
    outputExpression: Ref<string>,
    key: string
  ): void {
    inputExpression.value += key;
  }

  function handleOperatorKey(
    inputExpression: Ref<string>,
    outputExpression: Ref<string>,
    key: string
  ): void {
    inputExpression.value += key;
  }

  function handleFunctionKey(
    inputExpression: Ref<string>,
    outputExpression: Ref<string>,
    key: string
  ): void {
    inputExpression.value += key;
  }

  function handleSpecialKey(
    inputExpression: Ref<string>,
    outputExpression: Ref<string>,
    key: string
  ): void {
    const specialKey = specialKeys.find((k) => k.key === key);
    if (specialKey) {
      specialKey.trigger(inputExpression, outputExpression, key);
    }
  }

  function handleClick(
    inputExpression: Ref<string>,
    outputExpression: Ref<string>,
    key: string
  ): void {
    switch (checkKeyType(key)) {
      case "normal":
        return handleNumeralKey(inputExpression, outputExpression, key);
      case "operator":
        return handleOperatorKey(inputExpression, outputExpression, key);
      case "function":
        return handleFunctionKey(inputExpression, outputExpression, key);
      case "special":
        return handleSpecialKey(inputExpression, outputExpression, key);
    }
  }

  function showPreviewExpression(
    inputExpression: Ref<string>,
    outputExpression: Ref<string>
  ) {
    outputExpression.value = calculate(inputExpression.value);
  }

  return {
    numeralKeys,
    operatorKeys,
    functionKeys,
    specialKeys,
    handleNumeralKey,
    handleOperatorKey,
    handleFunctionKey,
    handleSpecialKey,
    handleClick,
    showPreviewExpression,
  };
});

export const useSimpleKeyboard = defineStore("simpleKeyboard", () => {
  const keyboard = ref([
    ["AC", "del", "%", "/"],
    ["7", "8", "9", "*"],
    ["4", "5", "6", "-"],
    ["1", "2", "3", "+"],
    ["ans", "0", ".", "="],
  ]);
  return {
    keyboard,
  };
});
