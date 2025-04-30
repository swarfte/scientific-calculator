// src/composables/math/Fraction.ts
export class Fraction {
  private _numerator: number;
  private _denominator: number;

  constructor(numerator: number, denominator: number = 1) {
    if (denominator === 0) throw new Error("Denominator cannot be zero");

    // Simplify the fraction upon creation
    const gcd = this.findGCD(Math.abs(numerator), Math.abs(denominator));
    const sign = denominator < 0 ? -1 : 1;

    this._numerator = sign * Math.round(numerator / gcd);
    this._denominator = Math.abs(Math.round(denominator / gcd));
  }

  get numerator(): number {
    return this._numerator;
  }

  get denominator(): number {
    return this._denominator;
  }

  get decimalValue(): number {
    return this._numerator / this._denominator;
  }

  private findGCD(a: number, b: number): number {
    return b === 0 ? a : this.findGCD(b, a % b);
  }

  // Basic operations
  add(fraction: Fraction): Fraction {
    const newNumerator =
      this._numerator * fraction.denominator +
      fraction.numerator * this._denominator;
    const newDenominator = this._denominator * fraction.denominator;
    return new Fraction(newNumerator, newDenominator);
  }

  subtract(fraction: Fraction): Fraction {
    const newNumerator =
      this._numerator * fraction.denominator -
      fraction.numerator * this._denominator;
    const newDenominator = this._denominator * fraction.denominator;
    return new Fraction(newNumerator, newDenominator);
  }

  multiply(fraction: Fraction): Fraction {
    return new Fraction(
      this._numerator * fraction.numerator,
      this._denominator * fraction.denominator
    );
  }

  divide(fraction: Fraction): Fraction {
    return new Fraction(
      this._numerator * fraction.denominator,
      this._denominator * fraction.numerator
    );
  }

  // Convert to string for display
  toString(): string {
    if (this._denominator === 1) return this._numerator.toString();
    return `${this._numerator}/${this._denominator}`;
  }

  // Convert number to fraction (with approximation if needed)
  static fromDecimal(
    decimal: number,
    maxDenominator: number = 10000
  ): Fraction {
    if (Number.isInteger(decimal)) return new Fraction(decimal, 1);

    let bestFraction = new Fraction(0, 1);
    let minError = Math.abs(decimal);

    for (let denominator = 1; denominator <= maxDenominator; denominator++) {
      const numerator = Math.round(decimal * denominator);
      const error = Math.abs(decimal - numerator / denominator);

      if (error < minError) {
        minError = error;
        bestFraction = new Fraction(numerator, denominator);

        // If error is very small, we've found a good approximation
        if (error < 1e-10) break;
      }
    }

    return bestFraction;
  }
}
