FROM python:3.11-bullseye

# Install system dependencies
RUN apt-get update && \
    apt-get install -y gcc g++ portaudio19-dev python3-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -v \
    -r requirements.txt \
    google-auth==2.27.0 \
    google-auth-oauthlib==1.2.0 \
    google-api-python-client==2.120.0 \
    oauth2client==4.1.3 \
    google-cloud-core==2.4.1 \
    google-cloud-storage==2.14.0

# Verification stage
RUN echo "=== Installation Verification ===" && \
    echo "\n### Installed Packages ###" && \
    pip list && \
    echo "\n### Google Package Files ###" && \
    find /usr/local/lib/python3.11/site-packages -name "*google*" -ls && \
    echo "\n### Python Path ###" && \
    python -c "import sys; print(sys.path)" && \
    echo "\n### Google Package Import Test ###" && \
    python -c "\
    try: \
        import google.auth; \
        from google.oauth2.credentials import Credentials; \
        print('Google imports successful'); \
    except Exception as e: \
        print(f'Google import failed: {e}'); \
        raise"

# Copy application code
COPY main.py .

# Set entrypoint
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]