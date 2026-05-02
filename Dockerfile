# استخدام نسخة مستقرة وخفيفة من Ubuntu
FROM ubuntu:22.04

# تثبيت الخدمات الأساسية (SSH و أدوات المساعدة)
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    && rm -rf /var/lib/apt/lists/*

# إعداد بيانات الدخول (خاصة بك)
# المستخدم: zin_user | كلمة المرور: ZinCloud@2024
RUN useradd -m -s /bin/bash zin_user && echo "zin_user:ZinCloud@2024" | chpasswd

# إعدادات أمان الـ SSH ليتوافق مع الاتصال السحابي
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/Port 22/Port 8080/' /etc/ssh/sshd_config

# فتح المنفذ 8080 (المنفذ الافتراضي لـ Cloud Run)
EXPOSE 8080

# تشغيل السيرفر
CMD ["/usr/sbin/sshd", "-D", "-e"]
