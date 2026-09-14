# bildirim_app
***bildirim demosu (api.py dosyasının en altına alınacak): 
@app.get("/demo-bildirim")
def demo_bildirim_gonder():
    try:
        mesaj = messaging.Message(
            notification=messaging.Notification(
                title='Danışman Sunumu - Canlı Test',
                body='Bu bildirim, proje savunması için manuel olarak tetiklenmiştir. Sistem kusursuz çalışıyor!',
            ),
            data={
                "link": "https://www.uludag.edu.tr/gemlik"
            },
            #kodda tanımlı olan TELEFON_TOKEN değişkenini kullanır
            token=TELEFON_TOKEN, 
        )
        messaging.send(mesaj)
        return {"durum": "Başarılı", "mesaj": "Demo bildirim telefona fırlatıldı!"}
    except Exception as e:
        return {"durum": "Hata", "detay": str(e)}

    >git push...sonrasında bu linke git: https://bildirim-sunucusu.onrender.com/demo-bildirim
***bildirim demosu (api.py dosyasının en altına alınacak):
@app.get("/demo-bildirim")
def demo_bildirim_gonder():
    try:
        mesaj = messaging.Message(
            notification=messaging.Notification(
                title='Danışman Sunumu - Canlı Test',
                body='Bu bildirim, proje savunması için manuel olarak tetiklenmiştir. Sistem kusursuz çalışıyor!',
            ),
            data={
                "link": "https://www.uludag.edu.tr/gemlik"
            },
            # Kodda tanımlı olan TELEFON_TOKEN değişkenini kullanır
            token=TELEFON_TOKEN, 
        )
        messaging.send(mesaj)
        return {"durum": "Başarılı", "mesaj": "Demo bildirim telefona fırlatıldı!"}
    except Exception as e:
        return {"durum": "Hata", "detay": str(e)}

        >git push...sonrasında bu linke git: https://bildirim-sunucusu.onrender.com/demo-bildirim
