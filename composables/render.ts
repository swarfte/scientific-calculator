import { type Character, CharacterFactory } from "@composables/character";

export class Render {
  constructor(private characters: Character[]) {}

  symbolRender() {
    const mappingList = {
      "×": "*",
      "÷": "/",
    };
    const result: string[] = [];
    const rawExpression = this.characters.map((character) => {
      return character.getValue();
    });

    // replace the symbols with their corresponding values
    for (const character of rawExpression) {
      if (character in mappingList) {
        result.push(mappingList[character as keyof typeof mappingList]);
      } else {
        result.push(character);
      }
    }
    // join the array into a string
    const joinedExpression = result.join("");
    return joinedExpression;
  }

  calculateRender() {
    const rawExpression = this.symbolRender();
    return rawExpression;
  }

  HTMLRender() {
    const rawExpression = this.characters.map((character) => {
      return character.getValue();
    });
    const joinedExpression = rawExpression.join("");
    const characterFactory = CharacterFactory.getInstance();
    const operationCharacter = characterFactory.getOperationCharacter();

    // Escape regex special characters in operation symbols
    const escapedOperations = operationCharacter.map((op) =>
      op.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    );

    // Create regex pattern with escaped operations
    const pattern = new RegExp(`(${escapedOperations.join("|")})`, "g");

    // Split the expression using the safe pattern
    const splitExpression = joinedExpression.split(pattern);

    const result: string[] = [];
    for (const character of splitExpression) {
      if (operationCharacter.includes(character)) {
        result.push(`<span class="operation">${character}</span> \n`);
      } else {
        result.push(`<span class="number">${character}</span> \n`);
      }
    }

    // Join the array into a string
    const htmlExpression = result.join("");
    return htmlExpression;
  }
}
