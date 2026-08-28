class PhysicsEngine {
  /// Newton's Second Law: F = m * a
  static double calculateForce(double mass, double acceleration) {
    return mass * acceleration;
  }

  /// Kinetic Energy: KE = 0.5 * m * v^2
  static double calculateKineticEnergy(double mass, double velocity) {
    return 0.5 * mass * velocity * velocity;
  }

  /// Ohm's Law: V = I * R
  static double calculateVoltage(double current, double resistance) {
    return current * resistance;
  }

  /// Ohm's Law: I = V / R
  static double calculateCurrent(double voltage, double resistance) {
    return voltage / resistance;
  }
}
