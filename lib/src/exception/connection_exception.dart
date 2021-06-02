class ConnectionException implements Exception {
  static final String Message = 'Some connection error.';
  final String message = Message;

  @override
  String toString() {
    return this.message;
  }
}
