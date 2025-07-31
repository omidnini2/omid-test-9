Voice Clone Free (Offline, Persian-Enabled)
===========================================

این مخزن نمونهٔ یک اپلیکیشن «تبدیل متن به گفتار با صدای کاربر» است که به‌صورت **کاملاً آفلاین** روی گوشی (Android/iOS) اجرا می‌شود و هیچ هزینهٔ اشتراک یا سرور خارجی ندارد.

ـــ ویژگی‌ها
1. اجرای مدل TTS + Voice-Cloning روی دستگاه با **ONNX Runtime Mobile**
2. پشتیبانی پیش‌فرض از **زبان فارسی** (مدل Coqui-TTS VITS-fa)
3. قابلیت ضبط نمونهٔ صدای کاربر (۱–۲ دقیقه)، استخراج Embedding و ذخیرهٔ محلی
4. رابط کاربری مینیمال Flutter برای تبدیل متن فارسی به گفتار و پخش/دانلود

ـــ ساختار پوشه‌ها
```
.
├── mobile_app/         # برنامهٔ Flutter (Android/iOS)
│   ├── lib/
│   │   └── main.dart   # UI + منطق ONNX
│   ├── pubspec.yaml
│   └── assets/
│       └── model.opt.onnx  # مدل کوانتیزه‌ی فارسی
├── model/
│   ├── download_and_export.sh  # اسکریپت دانلود مدل فارسی و تبدیل به ONNX
│   └── export_to_onnx.py       # اسکریپت پایتون برای تبدیل چک‌پوینت → ONNX
└── README.md
```

ـــ مراحل راه‌اندازی سریع
```bash
# 1) کلون
git clone https://github.com/<your_username>/voice_clone_free.git
cd voice_clone_free

# 2) دریافت مدل فارسی و تبدیل به ONNX (یک بار)
cd model
bash download_and_export.sh    # خروجی: mobile_app/assets/model.opt.onnx
cd ..

# 3) ساخت برنامهٔ Flutter
cd mobile_app
flutter pub get
flutter build apk   # یا flutter run روی دستگاه فیزیکی
```

ـــ توضیح بخش «model»
`download_and_export.sh` کارهای زیر را انجام می‌دهد:
1. نصب Coqui-TTS (اگر نصب نیست)
2. دانلود چک‌پوینت VITS فارسی آماده (`tts_models/fa/vits`) 
3. اجرای `export_to_onnx.py` برای تبدیل مدل به ONNX و سپس کوانتیزه با `onnxruntime-tools` به **FP16**
4. کپی فایل خروجی به `mobile_app/assets/model.opt.onnx`

ـــ نحوهٔ کلون صدای کاربر (Speaker Embedding)
در اولین اجرا اپ از کاربر می‌خواهد ~۱ دقیقه صدا ضبط کند. فایل WAV در storage محلی ذخیره می‌شود و با یک مدل **Speaker Encoder** فشرده (همراه با مدل TTS در ONNX) به `embedding.npy` تبدیل می‌شود. این بردار در حافظهٔ برنامه نگه‌داری می‌شود و برای تمام درخواست‌های بعدی به مدل TTS تزریق می‌شود تا خروجی با صدای کاربر تولید شود.

ـــ مجوز
کد تحت مجوز MIT ارائه می‌شود. مدل فارسی مورد استفاده دارای مجوز MPL-2.0 (Coqui-TTS) است؛ استفادهٔ شخصی و تجاری آزاد است مشروط به رعایت شرایط MPL.

برای جزئیات بیشتر به هر فایل در پوشه‌های مربوطه مراجعه کنید ✌️.