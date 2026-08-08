enum AngleMode {
  degree,
  radian;

  String get label {
    return switch (this) {
      AngleMode.degree => '度',
      AngleMode.radian => '弧度',
    };
  }
}
