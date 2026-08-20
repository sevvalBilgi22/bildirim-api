import requests
from bs4 import BeautifulSoup
import sqlite3 # 3. Gün: Veritabanı kütüphanesini dahil ettik. Harici kuruluma gerek yoktur, Python'la gelir.
import schedule
import time
import firebase_admin
from firebase_admin import credentials, messaging

# Firebase Yetki Belgesini Tanıtıyoruz (Sadece bir kere çalışır)
if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-admin.json")
    firebase_admin.initialize_app(cred)
    
TELEFON_TOKEN = "BURAYA_KENDI_UZUN_TOKEN_INI_YAPISTIR"

# --- YENİ EKLENEN VERİTABANI FONKSİYONLARI ---

def veritabani_kur():
    """
    Bu fonksiyon, eğer yoksa proje klasöründe 'bildirimler.db' adında bir dosya oluşturur
    ve içine 'duyurular' tablosunu ekler. SQL Server'daki CREATE TABLE mantığının aynısıdır.
    """
    conn = sqlite3.connect("bildirimler.db")
    cursor = conn.cursor()
    
    # site_adi: İleride birden fazla site ekleyeceğin için hangi sitenin duyurusu olduğunu tutar
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS duyurular (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            site_adi TEXT,
            baslik TEXT,
            link TEXT
        )
    ''')
    conn.commit()
    conn.close()

def duyuru_kontrol_et_ve_kaydet(site_adi, baslik, link):
    """
    4. Gün: Bu fonksiyon veritabanına bakar. Çekilen başlık veritabanında varsa bir şey yapmaz.
    Yoksa (yani yeniyse) veritabanına kaydeder ve "YENİ DUYURU" alarmı verir.
    """
    conn = sqlite3.connect("bildirimler.db")
    cursor = conn.cursor()

    # Veritabanında bu başlıkta bir kayıt var mı diye soruyoruz
    cursor.execute("SELECT * FROM duyurular WHERE baslik = ?", (baslik,))
    kayit = cursor.fetchone()

    if kayit:
        print(f"[{site_adi}] Yeni bir duyuru yok. Zaten en sonuncuyu biliyorum: {baslik}")
    else:
        print(f"🔔 [{site_adi}] İÇİN YEPYENİ BİR DUYURU VAR!")
        print("Başlık:", baslik)
        print("Link:", link)

        try:
            mesaj = messaging.Message(
                notification=messaging.Notification(
                    title=f'{site_adi} - Yeni Duyuru!',
                    body=baslik,
                ),
                data={
                    "link": link # İŞTE YENİ EKLENEN SİHİRLİ SATIR
                },
                token=TELEFON_TOKEN,
            )
            messaging.send(mesaj)

       
            messaging.send(mesaj)
            print("🚀 Bildirim telefona başarıyla fırlatıldı!")
        except Exception as e:
            print(f"❌ Bildirim gönderilemedi: {e}")

        
        # Gelecek haftalarda telefona bildirim gönderme kodunu tam buraya yazacağız!
        
        # Yeni duyuruyu sisteme "eski" olmaması için kaydediyoruz
        cursor.execute("INSERT INTO duyurular (site_adi, baslik, link) VALUES (?, ?, ?)", (site_adi, baslik, link))
        conn.commit()
        print("-> Yeni duyuru hafızaya (veritabanına) kaydedildi.")

    conn.close()

# --- ESKİ VERİ ÇEKME FONKSİYONUMUZ (GÜNCELLENDİ) ---

# --- ESKİ VERİ ÇEKME FONKSİYONUMUZ (10 DUYURU İÇİN GÜNCELLENDİ) ---

def son_duyuruyu_getir():
    url = "https://www.osym.gov.tr/Duyurular/Index" 
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, "html.parser")
        duyurular = soup.find_all("a", class_="duyuru-list-item")

        if duyurular:
            print("🔍 ÖSYM'den son 10 duyuru toplanıyor...")
            # Sadece 0. indeksi değil, [:10] ile ilk 10 elemanı alıp döngüye sokuyoruz
        for duyuru in reversed(duyurular[:10]):
                baslik = duyuru.get("title")
                link = duyuru.get("href")
                tam_link = f"https://www.osym.gov.tr{link}"
                # Her bir duyuruyu sırayla kontrole ve kayda gönderiyoruz
                duyuru_kontrol_et_ve_kaydet("ÖSYM", baslik, tam_link)
                
        else:
            print("Duyuru bulunamadı.")

    except Exception as e:
        print(f"Sistemsel bir hata oluştu: {e}")

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, "html.parser")
        duyurular = soup.find_all("a", class_="duyuru-list-item")

        if duyurular:
            en_guncel_duyuru = duyurular[0]
            baslik = en_guncel_duyuru.get("title")
            link = en_guncel_duyuru.get("href")
            tam_link = f"https://www.osym.gov.tr{link}"
            
            # Veri çekildikten sonra sadece ekrana yazdırmak yerine kontrol fonksiyonumuza gönderiyoruz!
            duyuru_kontrol_et_ve_kaydet("ÖSYM", baslik, tam_link)
            
        else:
            print("Duyuru bulunamadı.")

    except Exception as e:
        print(f"Sistemsel bir hata oluştu: {e}")

def uludag_duyurulari_getir():
    url = "https://www.uludag.edu.tr/gemlik/duyuru"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, "html.parser")
        
        # Uludağ Üniversitesi sayfasındaki genel duyuru bağlantılarını (a etiketlerini) arıyoruz
        duyurular = soup.find_all("a") 
        
        print("Üniversite sayfasından duyurular toplanıyor...")
        bulunan_duyuru_sayisi = 0
        
        for duyuru in reversed(duyurular): # Yine eskiden yeniye doğru kaydedelim
            baslik = duyuru.text.strip()
            link = duyuru.get("href")

            
            
            # Linkin boş olmadığını, duyuru içerdiğini ve başlığın anlamlı bir uzunlukta olduğunu kontrol edelim
            if link and ("duyuru" in link.lower() or "haber" in link.lower() or "gemlik" in link.lower()) and len(baslik) > 10:
                # Üniversite sitesindeki linkler bazen tam adres (https...) olmaz, başını biz ekleriz
                if not link.startswith("http"):
                    link = f"https://www.uludag.edu.tr{link}"
                    
                # Site adını "Üniversite" olarak kaydediyoruz ki Flutter'daki o sekmeye düşsün!
                duyuru_kontrol_et_ve_kaydet("Üniversite", baslik, link)
                bulunan_duyuru_sayisi += 1
                
                # Sadece son 10 tanesini almak için sınırı koyuyoruz
                if bulunan_duyuru_sayisi >= 10:
                    break

        if bulunan_duyuru_sayisi == 0:
            print("Üniversite duyurusu bulunamadı. HTML etiketlerini (class) sayfanın yapısına göre daha spesifik hale getirmemiz gerekebilir.")

    except Exception as e:
        print(f"Sistemsel bir hata oluştu: {e}")

# --- PROGRAMIN ÇALIŞMA SIRASI ---
# --- PROGRAMIN ÇALIŞMA SIRASI ---
def gorevleri_calistir():
    print("⏳ Zamanlanmış görev başlatılıyor...")
    son_duyuruyu_getir()       # 1. ÖSYM'yi kontrol et
    uludag_duyurulari_getir()  # 2. Üniversiteyi kontrol et

if __name__ == "__main__":
    veritabani_kur()
    
    # 1. Program açılır açılmaz beklemeden bir kere kontrol et
    gorevleri_calistir() 
    
    # 2. Zamanlayıcıyı kur: Her 12 saatte bir 'gorevleri_calistir' fonksiyonunu tetikle
    schedule.every(12).hours.do(gorevleri_calistir)
    
    print("⏰ Sistem aktif. Arka planda 12 saatte bir kontrol yapılıyor. (Çıkış için Ctrl+C)")
    
    # 3. Sonsuz Döngü: Programın kapanmasını engeller ve zamanı gelip gelmediğini sürekli kontrol eder
    while True:
        schedule.run_pending()
        time.sleep(1) # İşlemciyi (CPU) yormamak için her kontrolde 1 saniye dinlen