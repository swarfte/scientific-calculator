export interface CharacterData {
  [key: string]: any;
}

export abstract class Character {
  constructor(private type: string, private data: CharacterData) {}

  abstract export(): string;

  abstract getValue(): string;

  getType(): string {
    return this.type;
  }

  getRawData(): CharacterData {
    return this.data;
  }
}

export class EmptyCharacter extends Character {
  constructor() {
    super("empty", {});
  }

  override export(): string {
    return `<span class="empty"></span> \n`;
  }

  override getValue(): string {
    return "";
  }
}

export class NumberCharacter extends Character {
  constructor(private value: number) {
    super("number", { value });
  }

  override export(): string {
    return `<span class="number">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value.toString();
  }
}

export class PointCharacter extends Character {
  constructor(private value: string) {
    super("point", { value });
  }

  override export(): string {
    return `<span class="point">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value;
  }
}

export class OperationCharacter extends Character {
  constructor(private value: string) {
    super("symbol", { value });
  }

  override export(): string {
    return `<span class="operation">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value;
  }
}

export class FractionCharacter extends Character {
  constructor(private numerator: number, private denominator: number) {
    super("fraction", { numerator, denominator });
  }

  override export(): string {
    return `<span class="fraction">
                <span class="numerator">${this.numerator}</span>
                <span class="denominator">${this.denominator}</span>
            </span> \n`;
  }

  override getValue(): string {
    return `${this.numerator}/${this.denominator}`;
  }
}

export class ExecutionCharacter extends Character {
  constructor(
    private value: string,
    private action: (expression: Expression) => void
  ) {
    super("execution", { value });
  }

  execute(expression: Expression) {
    this.action(expression);
  }

  override export(): string {
    return `<span class="execution">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value;
  }
}

export class IndexCharacter extends Character {
  constructor() {
    super("index", { symbol: "|" });
  }

  override export(): string {
    return `<span class="index">${this.getRawData().symbol}</span> \n`;
  }

  override getValue(): string {
    return this.getRawData().symbol;
  }
}

export class CharacterFactory {
  private static instance: CharacterFactory = new CharacterFactory();
  private numberCharacter = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
  private operationCharacter = ["+", "-", "×", "÷", "(", ")", "*", "/", "%"];
  private fractionCharacter = ["#"]; // 1#3 for 1/3
  private pointCharacter = ["."];
  private executionCharacter = ["=", "DEL", "AC", "Ans"]; // for execution
  private constructor() {}

  static getInstance(): CharacterFactory {
    return CharacterFactory.instance;
  }

  getOperationCharacter() {
    return this.operationCharacter;
  }

  createCharacter(
    character: string,
    executeFunction?: (expression: Expression) => void
  ): Character {
    if (
      this.numberCharacter.includes(character) ||
      character.match(/^\d+(\.\d+)?$/)
    ) {
      return new NumberCharacter(parseInt(character));
    } else if (this.pointCharacter.includes(character)) {
      return new PointCharacter(character);
    } else if (this.operationCharacter.includes(character)) {
      return new OperationCharacter(character);
    } else if (this.executionCharacter.includes(character)) {
      return new ExecutionCharacter(
        character,
        executeFunction as (expression: Expression) => void
      );
    }
    return new EmptyCharacter(); // Return empty character for unknown input
  }
}
