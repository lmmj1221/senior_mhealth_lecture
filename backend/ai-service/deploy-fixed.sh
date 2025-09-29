#!/bin/bash

# Deploy AI Service to Cloud Run with Google AI SDK (Fixed)
# This uses Google AI API Key instead of Vertex AI to avoid regional model issues

set -e

# Get project ID
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo "Error: GCP project not set. Run 'gcloud config set project YOUR_PROJECT_ID'"
    exit 1
fi

echo "Deploying AI Service to Cloud Run..."
echo "Project: $PROJECT_ID"

# Deploy with Google AI API Key (avoiding Vertex AI issues)
gcloud run deploy senior-mhealth-ai \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v5 \
  --platform managed \
  --region asia-northeast3 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 5 \
  --allow-unauthenticated \
  --service-account=automation-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --set-env-vars="GOOGLE_AI_API_KEY=AIzaSyCX6sHFOok45cbRQQcC0gk7p32-a6J7yyk,MODEL_NAME=gemini-1.5-flash,ENVIRONMENT=production"

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe senior-mhealth-ai \
      --platform managed \
      --region asia-northeast3 \
      --format 'value(status.url)')

    echo "🌐 Service URL: $SERVICE_URL"
    echo "🏥 Health Check: $SERVICE_URL/health"
    echo "📊 Test Endpoint: $SERVICE_URL/test"

    # Test the service
    echo "Testing service..."
    curl -f "$SERVICE_URL/health" && echo "✅ Health check passed"
else
    echo "❌ Deployment failed"
    exit 1
fi