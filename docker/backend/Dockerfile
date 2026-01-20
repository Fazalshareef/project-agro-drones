FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy dependency file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose backend port
EXPOSE 5000

# Start application
CMD ["python", "app.py"]
