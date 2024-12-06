import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorData {
  final double temperature;
  final double humidity;

  SensorData({required this.temperature, required this.humidity});

  // JSON verisini bir SensorData nesnesine dönüştürme
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
    );
  }
}

class SensorService {
  final String baseUrl;

  SensorService(this.baseUrl);

  // Sensör verisini alma fonksiyonu
  Future<SensorData> fetchSensorData() async {
    final response = await http.get(Uri.parse('$baseUrl/sensor')).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      // Eğer istek başarılıysa, veriyi JSON olarak parse et
      final Map<String, dynamic> data = jsonDecode(response.body);
      return SensorData.fromJson(data);
    } else {
      throw Exception('Veri alınırken bir hata oluştu');
    }
  }
}
