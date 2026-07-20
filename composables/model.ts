export interface Title {
  title: string;
  icon: string;
}

export interface Key {
  key: string;
  type: string;
}

export interface NumeralKey extends Key {
  type: "normal";
}

export interface OperatorKey extends Key {
  type: "operator";
}

export interface FunctionKey extends Key {
  type: "function";
}

export interface SpecialKey extends Key {
  type: "special";
  trigger: (
    inputExpression: Ref<string>,
    outputExpression: Ref<string>,
    key: string
  ) => void;
}