import { create, all, type Matrix, type Complex } from "mathjs";

// Create a mathjs instance (recommended over using the global mathjs instance)
export const mathjs = create(all, {});

// Reactive variable to hold the current angle configuration.
// We use 'deg' as the default as requested.
const angleMode: Ref<"deg" | "rad" | "grad"> = ref("deg");

// Object to hold our custom, overridden trigonometric functions
const replacements: { [key: string]: any } = {};

// --- Wrap trigonometric functions (sin, cos, tan, sec, cot, csc) ---
// These functions take an angle as input and convert it based on angleMode for the original mathjs function.
const fnsInputConvert = ["sin", "cos", "tan", "sec", "cot", "csc"];
fnsInputConvert.forEach((name: string) => {
  // Get the original mathjs function
  // @ts-ignore
  const originalFn: any = mathjs[name]; // Use 'any' temporarily or find a more specific mathjs type if possible

  // Define the wrapper function for number inputs
  const wrapperFnNumber: (x: number) => number = function (x: number): number {
    // Convert input 'x' from the current angleMode to radians before calling the original function
    switch (angleMode.value) {
      case "deg":
        return originalFn((x / 180) * Math.PI);
      case "grad":
        return originalFn((x / 200) * Math.PI);
      default: // 'rad'
        return originalFn(x);
    }
  };

  // Create a typed-function wrapper to handle different input types (number, Array, Matrix)
  replacements[name] = mathjs.typed(name, {
    number: wrapperFnNumber, // Handle single number input
    // Handle Array or Matrix input by mapping the number wrapper over the elements
    "Array | Matrix": function (x: number[] | Matrix): number[] | Matrix {
      // Ensure the mapped function has access to angleMode.value and originalFn
      const mapFn = (value: any) => wrapperFnNumber(value);
      return mathjs.map(x, mapFn) as number[] | Matrix;
    },
  });
});

const fnsOutputConvert: string[] = [
  "asin",
  "acos",
  "atan",
  "atan2",
  "acot",
  "acsc",
  "asec",
];
fnsOutputConvert.forEach((name: string) => {
  // Get the original mathjs function
  // @ts-ignore
  const originalFn: any = mathjs[name];

  // Define the wrapper function for number inputs
  const wrapperFnNumber: (...args: number[]) => number | Complex = function (
    ...args: number[]
  ): number | Complex {
    // Call the original function (which returns result in radians)
    // Need to handle atan2 which takes two arguments
    const resultInRadians: any = originalFn(...args); // result can be number or Complex

    // If the result is a number, convert it from radians to the current angleMode
    if (typeof resultInRadians === "number") {
      switch (angleMode.value) {
        case "deg":
          return (resultInRadians / Math.PI) * 180; // radians to degrees
        case "grad":
          return (resultInRadians / Math.PI) * 200; // radians to gradians
        default: // 'rad'
          return resultInRadians; // result is already in radians
      }
    }

    // If the result is not a number (e.g., Complex number from asin(2)), return it directly
    return resultInRadians as number | Complex; // Return the original result
  };

  // Create a typed-function wrapper to handle different input types
  if (name === "atan2") {
    replacements[name] = mathjs.typed(name, {
      "number, number": wrapperFnNumber, // atan2 specifically takes two numbers
      // Add other required atan2 signatures if needed (e.g., Array, Matrix)
    });
  } else {
    replacements[name] = mathjs.typed(name, {
      number: wrapperFnNumber,
      // Handle Array or Matrix input
      "Array | Matrix": function (x: number[] | Matrix): number[] | Matrix {
        const mapFn = (value: any) => wrapperFnNumber(value); // wrapperFnNumber only takes angle value here
        return mathjs.map(x, mapFn) as number[] | Matrix;
      },
    });
  }
});

// After defining all wrappers, import them into the mathjs instance,
// overriding the built-in functions.
mathjs.import(replacements, { override: true });
