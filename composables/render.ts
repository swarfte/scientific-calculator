import { type Character, CharacterFactory } from "@composables/character";
import { Debug } from "#imports";
export class Render {
  constructor(
    private characters: Character[],
    private previousAnswer: number
  ) {}

  symbolRender() {
    const mappingList = {
      "×": "*",
      "÷": "/",
      "|": "", // hidden the index character
      Ans: this.previousAnswer.toString(),
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
    Debug.log("rawExpression : ", rawExpression);
    const joinedExpression = rawExpression.join("");
    const characterFactory = CharacterFactory.getInstance();
    const operationCharacter = characterFactory
      .getOperationCharacter()
      .concat("|");

    // Escape regex special characters in operation symbols
    const escapedOperations = operationCharacter.map((op) =>
      op.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    );

    // Create regex pattern with escaped operations
    const pattern = new RegExp(`(${escapedOperations.join("|")})`, "g");

    // Debug.log("joinedExpression : ", joinedExpression);
    // Split the expression using the safe pattern
    const splitExpression = joinedExpression.split(pattern);

    // remove empty strings from the array
    const filteredSplitExpression = splitExpression.filter((item) => {
      return item !== "";
    });
    Debug.log("filteredSplitExpression : ", filteredSplitExpression);

    //Debug.log("indexLocation : ", indexLocation);

    const result: string[] = [];

    for (const character of filteredSplitExpression) {
      result.push(characterFactory.createCharacter(character).export());
    }

    // Join the array into a string
    Debug.log("result:", result);
    const htmlExpression = result.join("");
    return htmlExpression;
  }
}
