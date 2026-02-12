class AppService {
  const AppService();

  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
