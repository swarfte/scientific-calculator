import {
  type Character,
  NumberCharacter,
  OperationCharacter,
  FractionCharacter,
  IndexCharacter,
} from "@composables/character";
import { evaluate } from "mathjs";
import { ref } from "vue";
import { Render } from "@composables/render";
import { Debug } from "@composables/debug";

export class Expression {
  private result = ref(0);
  private numerator = ref(0);
  private denominator = ref(1);
  private previousAnswer = ref(0);
  private indexLocation = ref(0);
  private characters = ref([new IndexCharacter()] as Character[]);
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

  getPreviousAnswer() {
    return this.previousAnswer;
  }

  getIndexLocation() {
    return this.indexLocation;
  }

  savePreviousAnswer() {
    this.previousAnswer.value = this.result.value;
    this.clear();
  }

  addCharacter(character: Character) {
    // add the character as the left side of the index character
    this.characters.value.splice(this.indexLocation.value, 0, character);
    this.indexLocation.value++;
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

  moveIndexLocation(index: number) {
    if (index >= 0 && index < this.characters.value.length) {
      this.indexLocation.value = index;
    } else {
      Debug.warn("Index out of bounds:", index);
    }
  }

  moveIndexLocationToEnd() {
    this.indexLocation.value = this.characters.value.length - 1;
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
      this.previousAnswer.value = this.result.value;
    } catch (error) {
      Debug.warn("Error evaluating expression:", error);
      this.result.value = this.previousAnswer.value;
    }
  }

  getCharacters() {
    return this.characters;
  }
  clear() {
    this.indexLocation.value = 0;
    this.characters.value = [new IndexCharacter()];
    this.result.value = 0;
    this.numerator.value = 0;
    this.denominator.value = 1;
  }

  removeLeftSideCharacter() {
    // remove the left side character of the index character
    if (this.indexLocation.value > 0) {
      this.characters.value.splice(this.indexLocation.value - 1, 1);
      this.indexLocation.value--;
    } else {
      Debug.warn("Index out of bounds:", this.indexLocation.value);
    }
    this.calculate();
  }

  removeCharacterAtIndex(index: number) {
    if (index >= 0 && index < this.characters.value.length) {
      this.characters.value.splice(index, 1);
    } else {
      Debug.warn("Index out of bounds:", index);
    }
  }
}
