import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(FireAlertApp());
}

class FireAlertApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire Detection System',
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

  void _addFireAlert(LatLng position) {
    // Örnek çevresel veriler
    double windSpeed = 15.0; // Rüzgar hızı (km/s)
    double temperature = 35.0; // Sıcaklık (°C)
    double humidity = 30.0; // Nem (%)

    // Yayılma hızını hesaplama (basit bir algoritma)
    double spreadSpeed =
        (windSpeed * 0.5) + (temperature * 0.3) - (humidity * 0.2);

    // Varsayılan bir yerleşim yeri mesafesi
    double distanceToSettlement = 10.0; // km

    // Yerleşim yerine ulaşma süresi (saat)
    double timeToSettlement = distanceToSettlement / spreadSpeed;

    final time = DateTime.now();
    final formattedTime =
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    final formattedDate =
        '${time.day}/${time.month}/${time.year}';

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
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(38.4192, 27.1287),
          initialZoom: 10.0,
          onTap: (tapPosition, point) {
            _addFireAlert(point);
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
