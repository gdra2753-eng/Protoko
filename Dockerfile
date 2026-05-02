# اختيار نظام التشغيل (ألبين خفيف جداً)
FROM alpine:latest

# تثبيت الأدوات اللازمة
RUN apk add --no-cache openssh-server bash curl

# إضافة مستخدم للـ SSH وتعيين كلمة المرور
RUN adduser -D android && echo "android:android10" | chpasswd

# توليد مفاتيح التشفير للسيرفر
RUN ssh-keygen -A 

# السماح بالاتصال عبر كلمة المرور
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# تحميل أداة التوصيل (wstunnel)
RUN curl -L https://github.com | tar -xz \
    && mv wstunnel /usr/local/bin/

# المنفذ الذي يطلبه Google Cloud Run
EXPOSE 8080

# أمر التشغيل النهائي (تشغيل الـ SSH والـ Websocket معاً)
CMD /usr/sbin/sshd && wstunnel server ws://0.0.0.0:8080 --restrictTo=127.0.0.1:22
