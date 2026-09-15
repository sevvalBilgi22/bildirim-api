from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3
from apscheduler.schedulers.background import BackgroundScheduler
import datetime
import feedparser
import scraper #kazıyıcı dosyanın içine aktarma
from firebase_admin import credentials, messaging
TELEFON_TOKEN = "fRITA0vCTtOIMhuH4oWglF:APA91bE7LTIbQ4iUy44J22BjLRArxfXVCjoDGno3hy35a3pTeNhE_5p6CddcXxRooiiTd_H0ucc43xJ_NQQMpVDoM4QteEOMQ25_uHiTJB0BZ7Bpkm1DW8Q"


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#veri tabanı kurulumu
#Uygulama başladığında tabloları kontrol eder yoksa oluşturur
def veritabani_kur():
    conn = sqlite3.connect("bildirimler.db")
    cursor = conn.cursor()
    #duyurular tablosu
    cursor.execute('''CREATE TABLE IF NOT EXISTS duyurular
                      (id INTEGER PRIMARY KEY AUTOINCREMENT,
                       site_adi TEXT, baslik TEXT, link TEXT, tarih TEXT)''')
    #talepler tablosu
    cursor.execute('''CREATE TABLE IF NOT EXISTS talepler
                      (id INTEGER PRIMARY KEY AUTOINCREMENT,
                       site_adi TEXT, url TEXT, tarih TEXT)''')
    conn.commit()
    conn.close()

veritabani_kur()

class SiteIstek(BaseModel):
    site_adi: str
    url: str

@app.post("/site-ekle")
def site_ekle(istek: SiteIstek):
    print(f"Yeni Site İsteği Geldi: {istek.site_adi} - {istek.url}")
    feed = feedparser.parse(istek.url)
    
    if feed.entries:
        print("Başarılı! RSS altyapısı bulundu.")
        return {"mesaj": "Site başarıyla eklendi!"} 
    else:
        #RSS yoksa siteyi talepler tablosuna kaydet
        print("RSS bulunamadı. Veritabanına talep olarak kaydediliyor.")
        conn = sqlite3.connect("bildirimler.db")
        cursor = conn.cursor()
        bugun = datetime.datetime.now().strftime("%d.%m.%Y")
        cursor.execute("INSERT INTO talepler (site_adi, url, tarih) VALUES (?, ?, ?)", 
                       (istek.site_adi, istek.url, bugun))
        conn.commit()
        conn.close()
        
        raise HTTPException(status_code=400, detail="Özel altyapı gerekiyor. Talep kaydedildi.")

@app.get("/duyurular")
def duyurulari_getir():
    try:
        conn = sqlite3.connect("bildirimler.db")
        cursor = conn.cursor()
        
        #50'den 250'ye çıkarıldı ki grup sekmelerine veri yetsin
        cursor.execute("SELECT site_adi, baslik, link, tarih FROM duyurular ORDER BY id DESC LIMIT 250")
        kayitlar = cursor.fetchall()
        conn.close()
        
        liste = []
        for kayit in kayitlar:
            liste.append({
                "site_adi": kayit[0],
                "baslik": kayit[1],
                "link": kayit[2],
                "tarih": kayit[3] 
            })
            
        return liste
    except Exception as e:
        return {"hata": str(e)}

def duyuru_kontrol_et_ve_kaydet():
    su_an = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{su_an}] Otopilot devrede: 4 saatlik rutin kontrol yapılıyor...")
    
    try:
        scraper.verileri_cek() 
        
        print(f"[{su_an}]Yeni duyurular başarıyla çekildi ve veritabanına eklendi.")
    except Exception as e:
        print(f"[{su_an}] Kazıma işlemi sırasında hata oluştu: {e}")

zamanlayici = BackgroundScheduler()
zamanlayici.add_job(duyuru_kontrol_et_ve_kaydet, 'interval', hours=1)  #Her 1 saatte bir çalışacak
if not zamanlayici.running:
    zamanlayici.start()

@app.get("/tetikle")
def manuel_tetikle():
    duyuru_kontrol_et_ve_kaydet() 
    return {"durum": "Başarılı", "mesaj": "Veriler anında çekildi ve kaydedildi!"}
    
zamanlayici.add_job(duyuru_kontrol_et_ve_kaydet, 'interval', hours=1)  #Her 4 saatte bir çalışacak
if not zamanlayici.running:
    zamanlayici.start()
