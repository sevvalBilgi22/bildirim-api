import firebase_admin
from firebase_admin import credentials, messaging

# 1. Firebase yetki belgemizi (JSON) tanıtıyoruz
# (Dosya adının klasördeki ile aynı olduğundan emin ol)
cred = credentials.Certificate("firebase-admin.json")
firebase_admin.initialize_app(cred)

# 2. Senin telefonunun az önce kopyaladığın kimliği
telefon_token = "fRITA0vCTtOIMhuH4oWglF:APA91bE7LTIbQ4iUy44J22BjLRArxfXVCjoDGno3hy35a3pTeNhE_5p6CddcXxRooiiTd_H0ucc43xJ_NQQMpVDoM4QteEOMQ25_uHiTJB0BZ7Bpkm1DW8Q"

# 3. Gönderilecek Bildirim İçeriği
mesaj = messaging.Message(
    notification=messaging.Notification(
        title='Sistem Başarıyla Kuruldu!',
        body='Python ve Firebase başarıyla el sıkıştı. 16. Gün tamamlandı!',
    ),
    token=telefon_token,
)

# 3. Gönderilecek Bildirim İçeriği
mesaj = messaging.Message(
    notification=messaging.Notification(
        title='19. Gün Testi!',
        body='Bana tıkla ve uygulama içinde ÖSYM sayfasını aç.',
    ),
    data={
        "link": "https://www.osym.gov.tr" # BİLDİRİMİN İÇİNE GİZLEDİĞİMİZ LİNK
    },
    token=telefon_token, # Dünkü kendi telefon token'ın
)

# 4. Bildirimi Fırlat!
try:
    response = messaging.send(mesaj)
    print('Harika! Bildirim başarıyla gönderildi! Firebase Onay Kodu:', response)
except Exception as e:
    print('Bir hata oluştu:', e)