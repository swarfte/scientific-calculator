import {
  type Character,
  NumberCharacter,
  OperationCharacter,
  FractionCharacter,
} from "@composables/character";
import { evaluate, gcd } from "mathjs";
import { ref } from "vue";
import { Render } from "@composables/render";

export class Expression {
  private characters = ref([] as Character[]);
  private result = ref(0);
  private numerator = ref(0);
  private denominator = ref(1);
  private static instance: Expression = new Expression(); // Singleton instance
  private constructor() {}

  static getInstance() {
    return Expression.instance;
  }

  getResult() {
    return this.result;
  }
  getNumerator() {
    return this.numerator;
  }

  getDenominator() {
    return this.denominator;
  }

  addCharacter(character: Character) {
    this.characters.value.push(character);
  }

  addNumber(number: number) {
    const character = new NumberCharacter(number);
    this.characters.value.push(character);
  }

  addOperation(operation: string) {
    const character = new OperationCharacter(operation);
    this.characters.value.push(character);
  }

  addFraction(numerator: number, denominator: number) {
    const character = new FractionCharacter(numerator, denominator);
    this.characters.value.push(character);
  }

  getExpression() {
    const render = new Render(this.characters.value as Character[]);
    return render.calculateRender();
  }

  getHTMLExpression() {
    const render = new Render(this.characters.value as Character[]);
    return render.HTMLRender();
  }

  calculate() {
    const render = new Render(this.characters.value as Character[]);
    const expression = render.calculateRender();

    try {
      // Use mathjs fraction functionality
      const result = evaluate(expression);
      this.result.value = result;

      // Convert to fraction (mathjs has a built-in function for this)
      const fraction = evaluate(`fraction(${result})`);
      this.numerator.value = fraction.n;
      this.denominator.value = fraction.d;
    } catch (error) {
      console.warn("Error evaluating expression:", error);
      this.result.value = NaN;
    }
  }

  getCharacters() {
    return this.characters;
  }
  clear() {
    this.characters.value = [];
    this.result.value = 0;
  }

  removeLastCharacter() {
    this.characters.value.pop();
  }

  removeCharacterAtIndex(index: number) {
    if (index >= 0 && index < this.characters.value.length) {
      this.characters.value.splice(index, 1);
    } else {
      console.error("Index out of bounds:", index);
    }
  }
}
