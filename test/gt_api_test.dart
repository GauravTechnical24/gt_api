import 'package:flutter_test/flutter_test.dart';
import 'package:gt_api/gt_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiConfig & ApiService Tests', () {
    setUp(() {
      ApiConfig().reset();
    });

    test('ApiConfig initializes with baseUrl and options', () {
      final config = ApiConfig();
      config.initialize(
        baseUrl: 'https://api.example.com',
        headers: {'Authorization': 'Bearer test_token'},
        enableLogs: false,
      );

      expect(config.baseUrl, 'https://api.example.com');
      expect(config.globalHeaders['Authorization'], 'Bearer test_token');
      expect(config.enableLogs, false);
    });

    test('ApiService initializes and references ApiConfig', () {
      final config = ApiConfig();
      config.initialize(baseUrl: 'https://api.example.com');

      final service = ApiService();
      service.initialize();

      expect(service.config.baseUrl, 'https://api.example.com');
      expect(service.dio.options.baseUrl, 'https://api.example.com');
    });
  });
}
