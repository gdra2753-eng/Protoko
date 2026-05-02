FROM ubuntu:22.04

RUN apt update && apt install -y openssh-server

# إنشاء مستخدم
RUN useradd -m android && echo "android:android10" | chpasswd

# إعداد SSH
RUN mkdir /var/run/sshd
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
