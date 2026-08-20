import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Arka planda bildirim geldi!");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase'i başlatıyoruz
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
 FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // 2. Bildirim izinlerini istiyoruz
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Kullanıcı bildirim izni durumu: ${settings.authorizationStatus}');
String? token = await messaging.getToken();
  print("fRITA0vCTtOIMhuH4oWglF:APA91bE7LTIbQ4iUy44J22BjLRArxfXVCjoDGno3hy35a3pTeNhE_5p6CddcXxRooiiTd_H0ucc43xJ_NQQMpVDoM4QteEOMQ25_uHiTJB0BZ7Bpkm1DW8Q: $token");
  runApp(const BildirimUygulamasi());
}

class BildirimUygulamasi extends StatelessWidget {
  const BildirimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Duyuru Merkezi',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F7FA),
        primaryColor: const Color(0xFF9C8CB9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C8CB9),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> tumDuyurular = [];
  bool yukleniyor = true;

 @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    verileriCek(); 

    // Uygulama arka plandayken bildirime tıklanırsa:
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _bildirimdenGelenLinkiAc(message);
    });

    // Uygulama tamamen kapalıyken bildirime tıklanırsa:
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _bildirimdenGelenLinkiAc(message);
      }
    });
  }

  // Bildirime tıklanınca çalışacak yeni fonksiyonumuz:
  void _bildirimdenGelenLinkiAc(RemoteMessage message) {
    if (message.data.containsKey('link')) {
      final String gelenLink = message.data['link'];
      
      launchUrl(
        Uri.parse(gelenLink),
        mode: LaunchMode.inAppWebView, // SİHİRLİ DOKUNUŞ BURASI
      );
    }
  }
  Future<void> verileriCek() async {
    try {
      // DİKKAT: Telefon için bilgisayarının yerel IP adresini yazmalısın! 
      // Örnek: 'http://192.168.1.35:8000/duyurular'
      final response = await http.get(Uri.parse('http://10.58.121.234:8000/duyurular')); 
      if (response.statusCode == 200) {
        setState(() {
          tumDuyurular = json.decode(response.body);
          yukleniyor = false;
        });
      }
    } catch (e) {
      print("Veri çekme hatası: $e");
      setState(() {
        yukleniyor = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Duyuru Merkezi',
          style: TextStyle(
            color: Color(0xFF4A4063),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C5DD3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6C5DD3),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'ÖSYM'),
            Tab(text: 'Üniversite'),
          ],
        ),
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C8CB9)))
          : TabBarView(
              controller: _tabController,
              children: [
                _duyuruListesiOlustur(tumDuyurular),
                _duyuruListesiOlustur(tumDuyurular.where((d) => d['site_adi'] == 'ÖSYM').toList()),
                _duyuruListesiOlustur(tumDuyurular.where((d) => d['site_adi'] == 'Üniversite').toList()),
              ],
            ),
    );
  }

  Widget _duyuruListesiOlustur(List<dynamic> duyurular) {
    if (duyurular.isEmpty) {
      return const Center(child: Text("Bu kategoride duyuru bulunamadı.", style: TextStyle(color: Colors.grey)));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: duyurular.length,
        itemBuilder: (context, index) {
          final duyuru = duyurular[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: PastelKartOrnegi(
              siteAdi: duyuru['site_adi'] ?? 'Bilinmiyor',
              baslik: duyuru['baslik'] ?? 'Başlıksız Duyuru',
              tarih: duyuru['tarih'] ?? '',
              link: duyuru['link'] ?? 'https://www.google.com',
            ),
          );
        },
      ),
    );
  }
}

class PastelKartOrnegi extends StatelessWidget {
  final String siteAdi;
  final String baslik;
  final String tarih;
  final String link;

  const PastelKartOrnegi({
    super.key,
    required this.siteAdi,
    required this.baslik,
    required this.tarih,
    required this.link,
  });

  Future<void> _linkiAc() async {
    final Uri url = Uri.parse(link);
    if (!await launchUrl(url)) {
      debugPrint('Link açılamadı: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _linkiAc,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C8CB9).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE6F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    siteAdi,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF65558F),
                    ),
                  ),
                ),
                Text(
                  tarih,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D1B20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}