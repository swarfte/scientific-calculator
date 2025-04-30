// src/composables/math/MathOperations.ts
export class MathOperations {
  static calculate(
    firstOperand: number,
    secondOperand: number,
    operator: string
  ): number {
    switch (operator) {
      case "+":
        return firstOperand + secondOperand;
      case "-":
        return firstOperand - secondOperand;
      case "×":
        return firstOperand * secondOperand;
      case "÷":
        return firstOperand / secondOperand;
      case "^":
        return Math.pow(firstOperand, secondOperand);
      default:
        return secondOperand;
    }
  }

  static logarithm(value: number, base: number): number {
    return Math.log(value) / Math.log(base);
  }

  static trigonometric(
    value: number,
    func: "sin" | "cos" | "tan",
    degrees: boolean = false
  ): number {
    const radians = degrees ? value * (Math.PI / 180) : value;
    switch (func) {
      case "sin":
        return Math.sin(radians);
      case "cos":
        return Math.cos(radians);
      case "tan":
        return Math.tan(radians);
      default:
        return 0;
    }
  }
}
