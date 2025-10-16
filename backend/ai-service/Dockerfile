# Fast Deployment - Using Base Image
FROM asia-northeast3-docker.pkg.dev/credible-runner-474101-f6/cloud-run-source-deploy/senior-mhealth-ai-base:latest

WORKDIR /app

# Copy application code only (dependencies already in base image)
COPY app ./app

# Run the application
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}