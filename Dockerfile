# استخدام نسخة خفيفة من أوبنتو
FROM ubuntu:22.04

# تثبيت SSH والخدمات اللازمة
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# إعداد مستخدم SSH (بناءً على الـ Config الخاص بك)
RUN useradd -m -s /bin/bash heli && \
    echo "heli:heli100" | chpasswd

# إعداد مجلد تشغيل SSH
RUN mkdir /var/run/sshd

# إضافة سكربت بسيط للقيام بدور Websocket Proxy على المنفذ 8080
# ليناسب طلب الـ Payload (Upgrade: Websocket)
RUN echo 'import socket, threading\n\
def handle(client_sock):\n\
    remote_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)\n\
    remote_sock.connect(("127.0.0.1", 22))\n\
    def forward(src, dst):\n\
        while True:\n\
            data = src.recv(4096)\n\
            if not data: break\n\
            dst.send(data)\n\
    threading.Thread(target=forward, args=(client_sock, remote_sock)).start()\n\
    threading.Thread(target=forward, args=(remote_sock, client_sock)).start()\n\
\n\
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)\n\
server.bind(("0.0.0.0", 8080))\n\
server.listen(5)\n\
while True:\n\
    client, addr = server.accept()\n\
    client.recv(1024) # استلام طلب الـ HTTP Payload وتجاهله للتحويل لـ SSH\n\
    handle(client)' > /proxy.py

# فتح المنافذ
EXPOSE 22 8080

# تشغيل الـ SSH والـ Proxy عند بدء الحاوية
CMD /usr/sbin/sshd && python3 /proxy.py
