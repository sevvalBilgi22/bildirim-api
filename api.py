from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sqlite3
from apscheduler.schedulers.background import BackgroundScheduler
import datetime

app = FastAPI()

# GÜVENLİK DUVARINI AŞAN CORS AYARLARI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/duyurular")
def duyurulari_getir():
    try:
        conn = sqlite3.connect("bildirimler.db")
        cursor = conn.cursor()
        
        # Duyuruları sondan başa (en yeni en üstte) olacak şekilde çek
        cursor.execute("SELECT site_adi, baslik, link FROM duyurular ORDER BY id DESC")
        kayitlar = cursor.fetchall()
        conn.close()
        
        # Verileri Flutter'ın anlayacağı sözlük (JSON) formatına çevir
        liste = []
        for kayit in kayitlar:
            liste.append({
                "site_adi": kayit[0],
                "baslik": kayit[1],
                "link": kayit[2],
                "tarih": "Yeni" 
            })
            
        return liste
    
    except Exception as e:
        return {"hata": str(e)}

# --- ZAMANLANMIŞ GÖREV FONKSİYONU ---
def otomatik_kontrol_yap():
    su_an = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{su_an}] ⏳ Otopilot devrede: Siteler kontrol ediliyor...")
    # İleride scraper entegrasyonu buraya gelecek

# --- ZAMANLAYICIYI BAŞLATMA ---
zamanlayici = BackgroundScheduler()
zamanlayici.add_job(otomatik_kontrol_yap, 'interval', minutes=1)
zamanlayici.start()