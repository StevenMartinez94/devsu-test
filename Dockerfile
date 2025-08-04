# Use official Python image
FROM python:3.13-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copying source code and dependencies into docker image
COPY . .

# Installing Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user and group with fixed UID and GID
RUN addgroup --system --gid 1000 apiuser \
    && adduser --system --uid 1000 --ingroup apiuser apiuser

# Change ownership of the work directory
RUN chown -R apiuser:apiuser /app

# Switch to non-root user
USER apiuser

# Expose port (for documentation only)
EXPOSE 8000

# Migrate the database and run the server
ENTRYPOINT ["sh", "-c", "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"]
