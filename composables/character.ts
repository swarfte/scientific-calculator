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
    return `<span class="${this.getType()}"></span> \n`;
  }

  override getValue(): string {
    return "";
  }
}

export class NumberCharacter extends Character {
  constructor(private value: string) {
    super("number", { value });
  }

  override export(): string {
    return `<span class="${this.getType()}">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value;
  }
}

export class PointCharacter extends Character {
  constructor(private value: string) {
    super("point", { value });
  }

  override export(): string {
    return `<span class="${this.getType()}">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value;
  }
}

export class OperationCharacter extends Character {
  constructor(private value: string) {
    super("operation", { value });
  }

  override export(): string {
    return `<span class="${this.getType()}">${this.value}</span> \n`;
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
    return `<span class="${this.getType()}">
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
    return `<span class="${this.getType()}">${this.value}</span> \n`;
  }

  override getValue(): string {
    return this.value;
  }
}

export class IndexCharacter extends Character {
  constructor() {
    super("animate-blink", { symbol: "|" });
  }

  override export(): string {
    return `<span class="${this.getType()}">${
      this.getRawData().symbol
    }</span> \n`;
  }

  override getValue(): string {
    return this.getRawData().symbol;
  }
}

export class CharacterFactory {
  private static instance: CharacterFactory = new CharacterFactory();
  private operationCharacter = [
    "+",
    "-",
    "×",
    "÷",
    "(",
    ")",
    "*",
    "/",
    "%",
    "sin(",
    "cos(",
    "tan(",
  ];
  private fractionCharacter = ["#"]; // 1#3 for 1/3
  private indexCharacter = ["|"]; // for index
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
    if (!isNaN(parseFloat(character))) {
      return new NumberCharacter(character);
    } else if (this.pointCharacter.includes(character)) {
      return new PointCharacter(character);
    } else if (this.operationCharacter.includes(character)) {
      return new OperationCharacter(character);
    } else if (this.executionCharacter.includes(character)) {
      return new ExecutionCharacter(
        character,
        executeFunction as (expression: Expression) => void
      );
    } else if (this.indexCharacter.includes(character)) {
      return new IndexCharacter();
    }
    return new EmptyCharacter(); // Return empty character for unknown input
  }
}
