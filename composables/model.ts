export interface KeyboardRow {
  id: number;
  buttons: KeyboardButton[];
}

export interface KeyboardButton {
  symbol: string;
  textColor?: string;
  triggerKey?: string;
  expressionSymbol?: string;
  backgroundColor?: string;
  shiftedSymbol?: string;
  shiftedTextColor?: string;
  shiftedBackgroundColor?: string;
  shiftedExpressionSymbol?: string;
  shiftedCallback?: (
    expression: Expression,
    characterFactory: CharacterFactory
  ) => void;
  callback?: (
    expression: Expression,
    characterFactory: CharacterFactory
  ) => void;
}
