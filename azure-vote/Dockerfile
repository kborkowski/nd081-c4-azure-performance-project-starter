# Pull the base image - using Python 3.11 slim
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install gunicorn for production serving
RUN pip install --no-cache-dir gunicorn

# Copy the application code
COPY . /app

# Expose port 80
EXPOSE 80

# Run the application with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "4", "--timeout", "60", "main:app"]
