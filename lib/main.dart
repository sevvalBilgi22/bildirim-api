import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Arka planda bildirim geldi!");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint("DİKKAT: Firebase başlatılıyor...");
    await Firebase.initializeApp();
    debugPrint("DİKKAT: Firebase başarıyla başlatıldı!");
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Kullanıcı izin durumu: ${settings.authorizationStatus}');
    
    debugPrint("DİKKAT: Token isteniyor...");
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("TELEFONUN ÖZEL TOKENİ: $token");
    
  } catch (e) {
    debugPrint("DİKKAT: Firebase başlatılamadı! İŞTE HATA SEBEBİ: $e");
  }

  // Uygulamayı başlatan kod en sonda
  runApp(const BildirimUygulamasi());
}

class BildirimUygulamasi extends StatelessWidget {
  const BildirimUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Web Bildirimlerim',
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
  int gosterilecekLimit = 15; // Limit Değişkeni
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    verileriCek(); 

    try {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _bildirimdenGelenLinkiAc(message);
      });

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _bildirimdenGelenLinkiAc(message);
        }
      });
    } catch (e) {
      print("Chrome'da test edildiği için bildirim dinleyicileri atlandı.");
    }
  }

  void _bildirimdenGelenLinkiAc(RemoteMessage message) {
    if (message.data.containsKey('link')) {
      final String gelenLink = message.data['link'];
      
      launchUrl(
        Uri.parse(gelenLink),
        mode: LaunchMode.inAppWebView, 
      );
    }
  } 

  //YENİ SİTE EKLEME
  void _siteEklemePenceresiniAc(BuildContext context) {
    final TextEditingController adController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    bool isSubmitting = false; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4, 
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    "Yeni Site Ekle", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "RSS destekli veya sistemde kayıtlı siteler anında eklenir.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: adController, 
                    decoration: InputDecoration(
                      hintText: "Site Adı (Örn: Uludağ Üniversitesi)",
                      filled: true,
                      fillColor: const Color(0xFFF4EFFF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.label_outline, color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: urlController, 
                    decoration: InputDecoration(
                      hintText: "Bağlantı (Örn: https://uludag.edu.tr)",
                      filled: true,
                      fillColor: const Color(0xFFF4EFFF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.link, color: Colors.deepPurple),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting ? null : () async {
                        final ad = adController.text.trim();
                        final url = urlController.text.trim();

                        if (ad.isEmpty || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lütfen her iki alanı da doldurun!"), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                        });

                        try {
                          final response = await http.post(
                            Uri.parse('https://bildirim-sunucusu.onrender.com/site-ekle'),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({'site_adi': ad, 'url': url}),
                          );

                          Navigator.pop(context); 

                          if (response.statusCode == 200 || response.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Site başarıyla eklendi!"), backgroundColor: Colors.green),
                            );
                            verileriCek(); 
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Bu site özel bir altyapıya sahip. Entegrasyon talebiniz alındı!"),
                                backgroundColor: Colors.deepPurple,
                              ),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sunucuya ulaşılamadı: $e"), backgroundColor: Colors.red),
                          );
                        } finally {
                          if (mounted) {
                            setModalState(() {
                              isSubmitting = false;
                            });
                          }
                        }
                      },
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Takip Et / Talep Gönder", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> verileriCek() async {
    try {
      final response = await http.get(Uri.parse('https://bildirim-sunucusu.onrender.com/duyurular')); 
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
        title: const Text('Web Bildirimlerim'),
        backgroundColor: const Color(0xFFF4EFFF),
        actions: [
          //LİMİT FİLTRESİ ANA EKRANA EKLENDİ
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list, color: Colors.deepPurple),
            tooltip: "Gösterilecek Duyuru Sayısı",
            onSelected: (int yeniLimit) {
              setState(() {
                gosterilecekLimit = yeniLimit; 
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(value: 10, child: Text('Son 10 Duyuru')),
              const PopupMenuItem<int>(value: 15, child: Text('Son 15 Duyuru')),
              const PopupMenuItem<int>(value: 20, child: Text('Son 20 Duyuru')),
              const PopupMenuItem<int>(value: 30, child: Text('Son 30 Duyuru')),
            ],
          ),
         
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.deepPurple),
            tooltip: "Hesabım",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HesabimEkrani()),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HakkindaEkrani()),
              );
            },
          child: ClipOval(
            child: Image.asset(
              'assets/iconn.jpg', 
              width: 36, 
              height: 36, 
              fit: BoxFit.cover, // Resmin yuvarlağa tam oturmasını sağlar
            ),
          ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'ÖSYM'),
            Tab(text: 'GAKMYO'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _siteEklemePenceresiniAc(context);
        },
        backgroundColor: const Color(0xFF9C8CB9),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _duyuruListesiOlustur(List<dynamic> duyurular) {
    final sinirliListe = duyurular.take(gosterilecekLimit).toList();

    if (sinirliListe.isEmpty) {
      return const Center(child: Text("Bu kategoride duyuru bulunamadı.", style: TextStyle(color: Colors.grey)));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: sinirliListe.length, 
        itemBuilder: (context, index) {
          final duyuru = sinirliListe[index]; 
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: PastelKartOrnegi(
              siteAdi: duyuru['site_adi'] == 'Üniversite' ? 'GAKMYO' : (duyuru['site_adi'] ?? 'Bilinmiyor'),
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
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      debugPrint('Link açılamadı: $url');
    }
  }

  bool _yeniMi(String tarihMetni) {
    if (tarihMetni.isEmpty) return false;
    
    try {
      // Tarihte nokta, tire veya eğik çizgi kullanılmış olabilir, hepsini standartlaştırıyoruz
      final temizTarih = tarihMetni.replaceAll('-', '.').replaceAll('/', '.');
      final parcalar = temizTarih.split('.'); 
      
      if (parcalar.length == 3) {
        final duyuruTarihi = DateTime(
          int.parse(parcalar[2].trim()), // Yıl
          int.parse(parcalar[1].trim()), // Ay
          int.parse(parcalar[0].trim()), // Gün
        );
        
        final fark = DateTime.now().difference(duyuruTarihi).inDays;
        
        
        return fark >= 0 && fark < 7; //7 gün sınırı
      }
    } catch (e) {
      return false; 
    }
    return false;
  }
  @override
  Widget build(BuildContext context) {
    final bool yeni = _yeniMi(tarih);

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
                Row(
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
                    const SizedBox(width: 8), 
                    if (yeni)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                        ),
                        child: const Text(
                          "Yeni",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  tarih,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
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

//GELİŞTİRİCİ HAKKINDA EKRANI
class HakkindaEkrani extends StatelessWidget {
  const HakkindaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hakkında"),
        backgroundColor: const Color(0xFFF4EFFF),
        foregroundColor: Colors.deepPurple, 
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           // Eski Hali: Image.asset('assets/iconn.jpg', width: 120, height: 120),
            ClipOval(
              child: Image.asset(
                'assets/iconn.jpg', 
                width: 120, 
                height: 120, 
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Web Bildirimlerim",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            const Text(
              "Sürüm: 3.0.1",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            const Text(
              "Geliştirici",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.deepPurple),
            ),
            const SizedBox(height: 5),
            const Text(
              "Şevval Ülkü Bilgi",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
            const Text(
              "Yayın Tarihi: Ağustos 2026",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 5),
            const Text(
              "Son Güncelleme: 20 Ağustos 2026",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
//HESABIM EKRANI
class HesabimEkrani extends StatelessWidget {
  const HesabimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      appBar: AppBar(
        title: const Text("Hesabım", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4EFFF),
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Y2K Polaroid Fotoğraf Çerçevesi
            Center(
              child: Container(
                padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    image: const DecorationImage(
                      image: AssetImage('assets/iconn.jpg'), 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              "Şevval Ülkü Bilgi",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D1B20)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Bilgisayar Programcısı | Yazılım Geliştirici | BUÜ GAKMYO",
              style: TextStyle(fontSize: 15, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),

          
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 6; i++)
                  const Icon(Icons.star, size: 18, color: Color(0xFF9C8CB9)),
                for (int i = 0; i < 2; i++)
                  const Icon(Icons.star_border, size: 18, color: Color(0xFF9C8CB9)),
              ],
            ),
            const SizedBox(height: 40),

            // Profil Ayarları Sekmeleri
            _ayarlarSekmesi(Icons.bookmark_border, "Kaydedilen Duyurular"),
            _ayarlarSekmesi(Icons.notifications_none, "Bildirim Tercihleri"),
            _ayarlarSekmesi(Icons.color_lens_outlined, "Tema Görünümü"),
            _ayarlarSekmesi(Icons.logout, "Çıkış Yap", isDestructive: true),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _ayarlarSekmesi(IconData ikon, String baslik, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: ListTile(
          leading: Icon(ikon, color: isDestructive ? Colors.redAccent : Colors.deepPurple),
          title: Text(baslik, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.black87, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () {}, // İleride buralara tıklama özellikleri eklenecek
        ),
      ),
    );
  }
}