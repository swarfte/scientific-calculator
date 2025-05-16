export class Debug {
  static log(...args: any[]) {
    // only show the message in development mode
    if (import.meta.env.DEV) {
      console.log(...args);
    }
  }

  static error(...args: any[]) {
    if (import.meta.env.DEV) {
      console.error(...args);
    }
  }

  static warn(...args: any[]) {
    if (import.meta.env.DEV) {
      console.warn(...args);
    }
  }

  static info(...args: any[]) {
    if (import.meta.env.DEV) {
      console.info(...args);
    }
  }

  static table(...args: any[]) {
    if (import.meta.env.DEV) {
      console.table(...args);
    }
  }

  static group(...args: any[]) {
    if (import.meta.env.DEV) {
      console.group(...args);
    }
  }

  static groupEnd() {
    if (import.meta.env.DEV) {
      console.groupEnd();
    }
  }

  static assert(condition: boolean, ...args: any[]) {
    if (import.meta.env.DEV) {
      console.assert(condition, ...args);
    }
  }
}
