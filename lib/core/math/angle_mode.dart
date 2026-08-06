enum AngleMode {
  degree,
  radian;

  String get label {
    return switch (this) {
      AngleMode.degree => 'DEG',
      AngleMode.radian => 'RAD',
    };
  }
}
