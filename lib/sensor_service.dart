import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorService {
  final String baseUrl; // Arduino'nun IP adresi veya API URL'si

  SensorService(this.baseUrl);

  /// Sensör verilerini çeken metot
  Future<SensorData> fetchSensorData() async {
    try {
      // Arduino'dan JSON verisi çek
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(Duration(seconds: 10)); // Zaman aşımı ekliyoruz

      if (response.statusCode == 200) {
        // Gelen veriyi ayrıştır
        final jsonData = json.decode(response.body);

        // Gelen JSON verisinin beklenen formatta olup olmadığını kontrol et
        if (!_validateJson(jsonData)) {
          throw Exception('Beklenen JSON formatı alınamadı.');
        }

        // JSON verisini SensorData nesnesine dönüştür
        return SensorData(
          temperature: (jsonData['temperature'] as num).toDouble(),
          humidity: (jsonData['humidity'] as num).toDouble(),
          isFire: jsonData['isFire'] as bool,
          country: jsonData['country'] as String,
          city: jsonData['city'] as String,
          latitude: (jsonData['latitude'] as num).toDouble(),
          longitude: (jsonData['longitude'] as num).toDouble(),
        );
      } else {
        throw Exception(
            'HTTP hatası: ${response.statusCode}. Sensör verisi alınamadı.');
      }
    } catch (e) {
      // Hata durumunda Exception fırlat
      throw Exception('Sensör verisi alınamadı: $e');
    }
  }

  /// Gelen JSON verisinin geçerli olup olmadığını kontrol eder
  bool _validateJson(Map<String, dynamic> jsonData) {
    return jsonData.containsKey('temperature') &&
        jsonData.containsKey('humidity') &&
        jsonData.containsKey('isFire') &&
        jsonData.containsKey('country') &&
        jsonData.containsKey('city') &&
        jsonData.containsKey('latitude') &&
        jsonData.containsKey('longitude');
  }
}

/// Sensör verilerini temsil eden model
class SensorData {
  final double temperature; // Sıcaklık (°C)
  final double humidity; // Nem (%)
  final bool isFire; // Yangın algılandı mı?
  final String country; // Ülke bilgisi
  final String city; // Şehir bilgisi
  final double latitude; // Enlem
  final double longitude; // Boylam

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.isFire,
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
  });
}
