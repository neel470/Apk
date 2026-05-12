FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH

RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    openjdk-17-jdk-headless \
    wget unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Android cmdline tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip -q commandlinetools-*.zip -d /tmp/cmdline-tools \
    && mkdir -p $ANDROID_HOME/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm -f commandlinetools-*.zip

# Accept licenses and install SDK
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 || true
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "build-tools;33.0.2" \
    "platforms;android-33" \
    > /dev/null 2>&1

# Install Python deps
RUN pip3 install flask werkzeug

WORKDIR /app
COPY . .

EXPOSE 5000

CMD ["python3", "app.py"]
