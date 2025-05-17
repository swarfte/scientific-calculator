export interface KeyboardRow {
  id: number;
  buttons: KeyboardButton[];
}

export interface KeyboardButton {
  symbol: string;
  textColor?: string;
  triggerKey?: string;
  backgroundColor?: string;
  callback?: (
    expression: Expression,
    characterFactory: CharacterFactory
  ) => void;
}
