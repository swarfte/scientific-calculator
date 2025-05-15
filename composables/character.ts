export abstract class Character {
  constructor(private type: string, private data: object) {}

  abstract export(): string;

  abstract getValue(): string;

  getType(): string {
    return this.type;
  }

  getRawData(): object {
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

export class CharacterFactory {
  private static instance: CharacterFactory = new CharacterFactory();
  private NumberCharacter = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
  private OperationCharacter = ["+", "-", "×", "÷", "(", ")", "*", "/", "%"];
  private FractionCharacter = ["#"]; // 1#3 for 1/3
  private ExecutionCharacter = ["=", "DEL", "AC", "Ans"]; // for execution
  private constructor() {}

  static getInstance(): CharacterFactory {
    return CharacterFactory.instance;
  }

  getOperationCharacter() {
    return this.OperationCharacter;
  }

  createCharacter(
    character: string,
    executeFunction?: (expression: Expression) => void
  ): Character {
    if (
      this.NumberCharacter.includes(character) ||
      character.match(/^\d+(\.\d+)?$/)
    ) {
      return new NumberCharacter(parseInt(character));
    } else if (character === ".") {
      return new PointCharacter(character);
    } else if (this.OperationCharacter.includes(character)) {
      return new OperationCharacter(character);
    } else if (this.FractionCharacter.includes(character)) {
      return new FractionCharacter(0, 0); // Placeholder for fraction
    } else if (this.ExecutionCharacter.includes(character)) {
      return new ExecutionCharacter(
        character,
        executeFunction as (expression: Expression) => void
      );
    }
    return new EmptyCharacter(); // Return empty character for unknown input
  }
}
