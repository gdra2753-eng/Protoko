# استخدام نسخة مستقرة وخفيفة
FROM ubuntu:22.04

# منع التفاعل أثناء التثبيت
ENV DEBIAN_FRONTEND=noninteractive

# تثبيت SSH، Python (للوسيط)، وأدوات الشبكة
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# إعداد SSH
RUN mkdir /var/run/sshd

# --- إعداد المستخدم (يجب أن يطابق الـ Config الخاص بك) ---
# سنستخدم متغيرات بيئة لسهولة التغيير لاحقاً
ENV SSH_USER=heli
ENV SSH_PASS=heli100

RUN useradd -m -s /bin/bash $SSH_USER && \
    echo "$SSH_USER:$SSH_PASS" | chpasswd

# السماح بتسجيل الدخول بكلمة المرور عبر SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# --- إنشاء سكربت الوسيط (WebSocket Proxy) ---
# هذا السكربت يستقبل طلب الـ Payload ويحول الاتصال لمنفذ SSH (22)
RUN echo 'import socket, threading\n\
def forward(source, destination):\n\
    try:\n\
        while True:\n\
            data = source.recv(4096)\n\
            if not data: break\n\
            destination.sendall(data)\n\
    except: pass\n\
\n\
def handle_client(client_sock):\n\
    try:\n\
        request = client_sock.recv(1024).decode("utf-8")\n\
        if "Upgrade: websocket" in request:\n\
            # الرد بالموافقة على ترقية الاتصال لـ Websocket\n\
            client_sock.sendall(b"HTTP/1.1 101 Switching Protocols\\r\\nUpgrade: websocket\\r\\nConnection: Upgrade\\r\\n\\r\\n")\n\
            \n\
            remote_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)\n\
            remote_sock.connect(("127.0.0.1", 22))\n\
            \n\
            threading.Thread(target=forward, args=(client_sock, remote_sock), daemon=True).start()\n\
            threading.Thread(target=forward, args=(remote_sock, client_sock), daemon=True).start()\n\
    except: client_sock.close()\n\
\n\
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)\n\
server.bind(("0.0.0.0", 8080))\n\
server.listen(100)\n\
print("Proxy running on port 8080...")\n\
while True:\n\
    client, _ = server.accept()\n\
    threading.Thread(target=handle_client, args=(client,), daemon=True).start()' > /ws_proxy.py

# فتح منفذ الـ Cloud Run الافتراضي
EXPOSE 8080

# تشغيل الـ SSH والوسيط معاً
CMD /usr/sbin/sshd && python3 /ws_proxy.py
