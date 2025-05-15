import { type Character, CharacterFactory } from "@composables/character";

export class Render {
  constructor(private characters: Character[]) {}

  symbolRender() {
    const mappingList = {
      "×": "*",
      "÷": "/",
    };
    const result: Character[] = [];
    for (const character of this.characters) {
      const type = character.getType();
      if (type === "empty") {
        continue;
      }
      if (type === "symbol") {
        const value = character.getValue();
        if (mappingList[value as keyof typeof mappingList]) {
          const mappedValue = mappingList[value as keyof typeof mappingList];
          const newCharacter =
            CharacterFactory.getInstance().createCharacter(mappedValue);
          result.push(newCharacter);
        } else {
          result.push(character);
        }
      } else {
        result.push(character);
      }
    }
    return result;
  }

  calculateRender() {
    const calculateExpression = this.symbolRender();
    let previousType = "empty";
    const tempQueue: string[] = [];
    const result: string[] = [];
    const characterFactory = CharacterFactory.getInstance();
    for (const character of calculateExpression) {
      const currentType = character.getType();
      if (currentType === "empty") {
        continue;
      }
      if (currentType === previousType && currentType === "number") {
        const previousCharacter = tempQueue.pop();
        if (previousCharacter) {
          const newCharacter = characterFactory.createCharacter(
            previousCharacter + character.getValue()
          );
          tempQueue.push(newCharacter.getValue());
        }
      } else {
        if (tempQueue.length > 0) {
          const previousCharacter = tempQueue.pop();
          if (previousCharacter) {
            result.push(previousCharacter);
          }
        }
        tempQueue.push(character.getValue());
      }
      previousType = currentType;
    }
    // Add the last character in the tempQueue to the result
    if (tempQueue.length > 0) {
      const previousCharacter = tempQueue.pop();
      if (previousCharacter) {
        result.push(previousCharacter);
      }
    }

    // if the last character is not a number, remove it
    if (result.length > 0) {
      const lastCharacter = result[result.length - 1];
      if (isNaN(Number(lastCharacter)) && lastCharacter !== ")") {
        result.pop();
      }
    }

    return result.map((character) => character).join(" ");
  }

  HTMLRender() {
    let previousType = "empty";
    const tempQueue: Character[] = [];
    const result: Character[] = [];
    const characterFactory = CharacterFactory.getInstance();

    for (const character of this.characters) {
      const currentType = character.getType();
      if (currentType === "empty") {
        continue;
      }
      if (currentType === previousType && currentType === "number") {
        const previousCharacter = tempQueue.pop();
        if (previousCharacter) {
          const newCharacter = characterFactory.createCharacter(
            previousCharacter.getValue() + character.getValue()
          );
          tempQueue.push(newCharacter);
        }
      } else {
        if (tempQueue.length > 0) {
          const previousCharacter = tempQueue.pop();
          if (previousCharacter) {
            result.push(previousCharacter);
          }
        }
        tempQueue.push(character);
      }
      previousType = currentType;
    }

    // Add the last character in the tempQueue to the result
    if (tempQueue.length > 0) {
      const previousCharacter = tempQueue.pop();
      if (previousCharacter) {
        result.push(previousCharacter);
      }
    }
    return result.map((character) => character.export()).join(" ");
  }
}
