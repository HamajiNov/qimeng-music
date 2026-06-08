FROM python:3.11-slim

# 系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    fluidsynth \
    ffmpeg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 安装 Audiveris
RUN wget -q https://github.com/Audiveris/audiveris/releases/latest/download/Audiveris-Linux.deb \
    -O /tmp/audiveris.deb && \
    dpkg -i /tmp/audiveris.deb || apt-get install -f -y && \
    rm /tmp/audiveris.deb

WORKDIR /app

# Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 应用代码
COPY . .

# 创建数据目录
RUN mkdir -p data/input data/output data/soundfonts

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
