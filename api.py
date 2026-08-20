from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3
from apscheduler.schedulers.background import BackgroundScheduler
import datetime
import feedparser # RSS kontrolü için eklediğimiz yeni kütüphane

app = FastAPI()

# GÜVENLİK DUVARINI AŞAN CORS AYARLARI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- FLUTTER'DAN GELECEK VERİNİN İSKELETİ ---
class SiteIstek(BaseModel):
    site_adi: str
    url: str

# --- YENİ EKLENEN SİTE EKLEME KAPISI ---
@app.post("/site-ekle")
def site_ekle(istek: SiteIstek):
    print(f"Yeni Site İsteği Geldi: {istek.site_adi} - {istek.url}")
    
    # URL'ye gidip orada evrensel bir RSS yapısı var mı diye bakıyoruz
    feed = feedparser.parse(istek.url)
    
    # Eğer feed.entries doluysa, bu site RSS destekliyor demektir!
    if feed.entries:
        print("Başarılı! RSS altyapısı bulundu.")
        # Şimdilik veritabanına eklemiyoruz, sadece Flutter'a "Tamamdır" mesajı (200 OK) dönüyoruz.
        return {"mesaj": "Site başarıyla eklendi!"} 
    
    else:
        # RSS yoksa 400 Bad Request fırlatıyoruz. 
        # Flutter bunu görünce o havalı "Özel Altyapı Talebi Alındı" uyarısını basacak!
        print("RSS bulunamadı. Bu site için özel HTML Scraper (kazıyıcı) yazılmalı.")
        raise HTTPException(status_code=400, detail="Özel altyapı gerekiyor.")

@app.get("/duyurular")
def duyurulari_getir():
    try:
        conn = sqlite3.connect("bildirimler.db")
        cursor = conn.cursor()
        
        # 1. DEĞİŞİKLİK: 'tarih' sütununu da çekiyoruz.
        # 2. DEĞİŞİKLİK: LIMIT 50 ekleyerek veritabanını yormuyoruz.
        cursor.execute("SELECT site_adi, baslik, link, tarih FROM duyurular ORDER BY id DESC LIMIT 50")
        kayitlar = cursor.fetchall()
        conn.close()
        
        liste = []
        for kayit in kayitlar:
            liste.append({
                "site_adi": kayit[0],
                "baslik": kayit[1],
                "link": kayit[2],
                "tarih": kayit[3] # <-- Artık "Yeni" kelimesi değil, veritabanındaki gerçek tarih!
            })
            
        return liste
    
    except Exception as e:
        return {"hata": str(e)}

def otomatik_kontrol_yap():
    su_an = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{su_an}] Otopilot devrede: Siteler kontrol ediliyor...")

zamanlayici = BackgroundScheduler()
zamanlayici.add_job(otomatik_kontrol_yap, 'interval', minutes=1)
zamanlayici.start()