export class Keyboard {
  private static instance: Keyboard = new Keyboard();
  private isShifted = ref(false);
  private keyboardRow = reactive<KeyboardRow[]>([]);

  private constructor() {}
  static getInstance() {
    return Keyboard.instance;
  }

  getIsShifted() {
    return this.isShifted;
  }

  setIsShifted(isShifted: boolean) {
    this.isShifted.value = isShifted;
  }

  toggleShift() {
    this.isShifted.value = !this.isShifted.value;
  }

  getKeyboardRow() {
    Debug.info("getKeyboardRow:", this.keyboardRow);
    return this.keyboardRow;
  }

  addKeyboardRow(keyboardRow: KeyboardRow) {
    this.keyboardRow.push(keyboardRow);
  }

  setKeyboardRow(keyboardRow: KeyboardRow[]) {
    this.keyboardRow = keyboardRow;
  }
}

export class KeyboardRow {
  private static counter = 0;
  private id: number;
  private keyboardButtons = [] as KeyboardButton[];
  constructor(buttons: KeyboardButton[]) {
    this.id = KeyboardRow.counter;
    KeyboardRow.counter++;
    this.keyboardButtons = buttons;
  }

  getId() {
    return this.id;
  }

  getKeyboardButtons() {
    Debug.info("getButtons:", this.keyboardButtons);
    return this.keyboardButtons;
  }
}

export class KeyboardButton {
  private symbol: string;
  private textColor?: string;
  private triggerKey?: string;
  private expressionSymbol?: string;
  private backgroundColor?: string;
  callback?: (
    expression: Expression,
    characterFactory: CharacterFactory
  ) => void;

  constructor(button: {
    symbol: string;
    textColor?: string;
    triggerKey?: string;
    expressionSymbol?: string;
    backgroundColor?: string;
    callback?: (
      expression: Expression,
      characterFactory: CharacterFactory
    ) => void;
  }) {
    this.symbol = button.symbol;
    this.textColor = button.textColor;
    this.triggerKey = button.triggerKey;
    this.expressionSymbol = button.expressionSymbol;
    this.backgroundColor = button.backgroundColor;
    this.callback = button.callback;
  }

  getSymbol() {
    return this.symbol;
  }

  getTextColor() {
    return this.textColor;
  }

  getTriggerKey() {
    return this.triggerKey;
  }

  getExpressionSymbol() {
    return this.expressionSymbol;
  }

  getBackgroundColor() {
    return this.backgroundColor;
  }

  getCallback() {
    return this.callback;
  }
}

export interface KeyboardDictionary {
  [key: string]: KeyboardButton;
}

// the implementation of the keyboard button
export const buttons: KeyboardDictionary = {
  "0": new KeyboardButton({ symbol: "0" }),
  ".": new KeyboardButton({ symbol: "." }),
  Ans: new KeyboardButton({ symbol: "Ans", triggerKey: "tab" }),
  "%": new KeyboardButton({ symbol: "%" }),
  "=": new KeyboardButton({
    symbol: "=",
    triggerKey: "Enter",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, characterFactory: CharacterFactory) => {
      expression.savePreviousAnswer();
      const previousAnswer = expression.getPreviousAnswer();
      const character = characterFactory.createCharacter(
        String(previousAnswer.value)
      );
      expression.addCharacter(character);
      // Debug.info('Current Expression:', expression.getExpression());
      expression.moveIndexLocationToEnd();
      expression.calculate(); // for display the answer value
    },
  }),
  "1": new KeyboardButton({ symbol: "1" }),
  "2": new KeyboardButton({ symbol: "2" }),
  "3": new KeyboardButton({ symbol: "3" }),
  "+": new KeyboardButton({ symbol: "+" }),
  "-": new KeyboardButton({ symbol: "-" }),
  "4": new KeyboardButton({ symbol: "4" }),
  "5": new KeyboardButton({ symbol: "5" }),
  "6": new KeyboardButton({ symbol: "6" }),
  "×": new KeyboardButton({ symbol: "×", triggerKey: "*" }),
  "÷": new KeyboardButton({ symbol: "÷", triggerKey: "/" }),
  "7": new KeyboardButton({ symbol: "7" }),
  "8": new KeyboardButton({ symbol: "8" }),
  "9": new KeyboardButton({ symbol: "9" }),
  "⌫": new KeyboardButton({
    symbol: "⌫",
    triggerKey: "backspace",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      expression.removeLeftSideCharacter();
    },
  }),
  AC: new KeyboardButton({
    symbol: "AC",
    triggerKey: "\\",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      expression.clear();
    },
  }),
  RCL: new KeyboardButton({ symbol: "RCL" }),
  Log: new KeyboardButton({ symbol: "Log" }),
  "(": new KeyboardButton({ symbol: "(" }),
  ")": new KeyboardButton({ symbol: ")" }),
  "S⇔D": new KeyboardButton({ symbol: "S⇔D" }),
  "x^2": new KeyboardButton({ symbol: "x^2" }),
  "x^y": new KeyboardButton({ symbol: "x^y" }),
  Sin: new KeyboardButton({
    symbol: "Sin",
    triggerKey: "s",
    expressionSymbol: "sin(",
  }),
  Cos: new KeyboardButton({
    symbol: "Cos",
    triggerKey: "c",
    expressionSymbol: "cos(",
  }),
  Tan: new KeyboardButton({
    symbol: "Tan",
    triggerKey: "t",
    expressionSymbol: "tan(",
  }),
  "x/y": new KeyboardButton({ symbol: "x/y" }),
  "√x": new KeyboardButton({ symbol: "√x" }),
  aSin: new KeyboardButton({ symbol: "aSin", expressionSymbol: "asin(" }),
  aCos: new KeyboardButton({ symbol: "aCos", expressionSymbol: "acos(" }),
  aTan: new KeyboardButton({ symbol: "aTan", expressionSymbol: "atan(" }),
  Shift: new KeyboardButton({
    symbol: "Shift",
    backgroundColor: "bg-green-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      Debug.info("asin(0.5) = ", mathjs.evaluate("asin(0.5)"));
    },
  }),
  "△": new KeyboardButton({
    symbol: "△",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      expression.moveIndexLocationToStart();
    },
  }),
  "▽": new KeyboardButton({
    symbol: "▽",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      expression.moveIndexLocationToEnd();
    },
  }),
  "◁": new KeyboardButton({
    symbol: "◁",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      expression.moveIndexLocationToLeft();
    },
  }),
  "▷": new KeyboardButton({
    symbol: "▷",
    textColor: "text-black",
    backgroundColor: "bg-amber-500",
    callback: (expression: Expression, _characterFactory: CharacterFactory) => {
      expression.moveIndexLocationToRight();
    },
  }),
};
