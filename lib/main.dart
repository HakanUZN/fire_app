import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'sensor_service.dart';

void main() {
  runApp(FireAlertApp());
}

class FireAlertApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yangın Tespit Sistemi',
      theme: ThemeData(primarySwatch: Colors.red),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<String> notifications = [];
  List<LatLng> fireLocations = [];
  late SensorService sensorService;
  SensorData? sensorData;

  @override
  void initState() {
    super.initState();
    sensorService = SensorService('http://10.10.0.2');
    fetchSensorData();

    Timer.periodic(Duration(seconds: 30), (timer) {
      fetchSensorData();
    });
  }

  Future<void> fetchSensorData() async {
    try {
      final data = await sensorService.fetchSensorData();
      setState(() {
        sensorData = data;

        // Eğer yangın algılandıysa ve konum bilgisi mevcutsa
        if (sensorData!.isFire) {
          final fireLocation = LatLng(sensorData!.latitude, sensorData!.longitude);
          if (!fireLocations.contains(fireLocation)) {
            fireLocations.add(fireLocation); // Fire iconunu haritaya ekle
          }
          // Bildirim eklemek için
          _addFireAlert(fireLocation);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sensör verisi alınamadı. Lütfen bağlantınızı kontrol edin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _addFireAlert(LatLng position) {
    double windSpeed = 15.0;
    double temperature = sensorData?.temperature ?? 35.0;
    double humidity = sensorData?.humidity ?? 30.0;

    double spreadSpeed =
        (windSpeed * 0.5) + (temperature * 0.3) - (humidity * 0.2);

    double distanceToSettlement = 10.0;
    double timeToSettlement = distanceToSettlement / spreadSpeed;

    final time = DateTime.now();
    final formattedTime =
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    final formattedDate = '${time.day}/${time.month}/${time.year}';

    setState(() {
      fireLocations.add(position);
      notifications.insert(
        0,
        'Yangın uyarısı: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}) - '
            '$formattedDate $formattedTime\n'
            'Yayılma Hızı: ${spreadSpeed.toStringAsFixed(2)} km/s\n'
            'Yerleşim yerine ulaşma süresi: ${timeToSettlement.toStringAsFixed(2)} saat',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Yangın bildirimi eklendi!\n'
              'Yayılma Hızı: ${spreadSpeed.toStringAsFixed(2)} km/s\n'
              'Yerleşim yerine ulaşma süresi: ${timeToSettlement.toStringAsFixed(2)} saat',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yangın Tespit Sistemi'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationScreen(notifications: notifications),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (sensorData != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sıcaklık: ${sensorData!.temperature.toStringAsFixed(1)} °C',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Nem: ${sensorData!.humidity.toStringAsFixed(1)} %',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Yangın Durumu: ${sensorData!.isFire ? "Evet" : "Hayır"}',
                        style: TextStyle(
                          fontSize: 18,
                          color: sensorData!.isFire ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        'Alev: ${sensorData!.flame}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Gaz: ${sensorData!.gas}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Hareket: ${sensorData!.motion}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Konum: ${sensorData!.latitude.toStringAsFixed(4)}, ${sensorData!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                      Text(
                        'Bölge: ${sensorData!.city}, ${sensorData!.country}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(38.4192, 27.1287),
                initialZoom: 10.0,
                onTap: (tapPosition, point) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Yangın Bildirimi"),
                      content: Text("Bu konumda yangın bildirimi yapmak istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          child: Text("İptal"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          child: Text("Evet"),
                          onPressed: () {
                            _addFireAlert(point);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: fireLocations
                      .map(
                        (location) => Marker(
                      point: location,
                      child: Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  )
                      .toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          if (notifications.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange),
                    title: Text(notifications[index]),
                  );
                },
              ),
            ),
          ElevatedButton(
            onPressed: fetchSensorData,
            child: Text('Sensör Verilerini Güncelle'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text(
                'Menü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Yakındaki Bildirimler'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Güvenlik İpuçları'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ayarlar'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final List<String> notifications;

  NotificationScreen({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirimler'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text(notifications[index]),
          );
        },
      ),
    );
  }
}