import { create, all } from "mathjs";

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
        return originalFn((x / 360) * 2 * Math.PI);
      case "grad":
        return originalFn((x / 400) * 2 * Math.PI);
      default: // 'rad'
        return originalFn(x);
    }
  };

  // Create a typed-function wrapper to handle different input types (number, Array, Matrix)
  replacements[name] = mathjs.typed(name, {
    number: wrapperFnNumber, // Handle single number input
    // Handle Array or Matrix input by mapping the number wrapper over the elements
  });
});

// After defining all wrappers, import them into the mathjs instance,
// overriding the built-in functions.
mathjs.import(replacements, { override: true });
