import {
  type Character,
  NumberCharacter,
  OperationCharacter,
  FractionCharacter,
  IndexCharacter,
} from "@composables/character";
import { mathjs } from "@composables/math";
import { ref } from "vue";
import { Render } from "@composables/render";
import { Debug } from "@composables/debug";

export class Expression {
  private result = ref(0);
  private numerator = ref(0);
  private denominator = ref(1);
  private previousAnswer = ref(0);
  private indexLocation = ref(0);
  private tempAnswer = ref(0);
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

  getTempAnswer() {
    return this.tempAnswer;
  }

  savePreviousAnswer() {
    this.previousAnswer.value = this.result.value;
    this.indexLocation.value = 0;
    this.characters.value = [new IndexCharacter()];
    this.result.value = 0;
  }

  addCharacter(character: Character) {
    // add the character as the left side of the index character
    this.characters.value.splice(this.indexLocation.value, 0, character);
    this.indexLocation.value++;
  }

  addNumber(number: number) {
    const character = new NumberCharacter(String(number));
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
    const render = new Render(
      this.characters.value as Character[],
      this.previousAnswer.value
    );
    return render.calculateRender();
  }

  getHTMLExpression() {
    const render = new Render(
      this.characters.value as Character[],
      this.previousAnswer.value
    );
    return render.HTMLRender();
  }

  moveIndexLocation(index: number) {
    if (index >= 0 && index < this.characters.value.length) {
      this.indexLocation.value = index;
    } else {
      Debug.warn("Index out of bounds:", index);
    }
  }

  moveIndexLocationToStart() {
    // remove the index character from the expression by the index location
    this.characters.value.splice(this.indexLocation.value, 1);
    // add the index character to the start of the expression
    this.characters.value.unshift(new IndexCharacter());
    // set the index location to the start of the expression
    this.indexLocation.value = 0;
  }

  moveIndexLocationToEnd() {
    // remove the index character from the expression by the index location
    this.characters.value.splice(this.indexLocation.value, 1);
    // add the index character to the end of the expression
    this.characters.value.push(new IndexCharacter());
    // set the index location to the end of the expression
    this.indexLocation.value = this.characters.value.length - 1;
  }

  moveIndexLocationToLeft() {
    if (this.indexLocation.value > 0) {
      // remove the index character from the expression by the index location
      this.characters.value.splice(this.indexLocation.value, 1);
      // add the index character to the left of the expression
      this.characters.value.splice(
        this.indexLocation.value - 1,
        0,
        new IndexCharacter()
      );
      // set the index location to the left of the expression
      this.indexLocation.value--;
    } else {
      Debug.warn("Index out of bounds:", this.indexLocation.value);
    }
  }

  moveIndexLocationToRight() {
    if (this.indexLocation.value < this.characters.value.length) {
      // remove the index character from the expression by the index location
      this.characters.value.splice(this.indexLocation.value, 1);
      // add the index character to the right of the expression
      this.characters.value.splice(
        this.indexLocation.value + 1,
        0,
        new IndexCharacter()
      );
      // set the index location to the right of the expression
      this.indexLocation.value++;
    } else {
      Debug.warn("Index out of bounds:", this.indexLocation.value);
    }
  }

  calculate() {
    const render = new Render(
      this.characters.value as Character[],
      this.previousAnswer.value
    );
    const expression = render.calculateRender();

    try {
      // Use mathjs fraction functionality
      const rawResult = mathjs.evaluate(expression);
      this.result.value = Number(mathjs.format(rawResult, { precision: 14 }));

      // Convert to fraction (mathjs has a built-in function for this)
      const fraction = mathjs.evaluate(`fraction(${rawResult})`);
      this.numerator.value = fraction.n;
      this.denominator.value = fraction.d;
      this.tempAnswer.value = rawResult;
    } catch (error) {
      Debug.warn("Error evaluating expression:", error);
      this.result.value = this.tempAnswer.value; // use the previous step answer
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
}
