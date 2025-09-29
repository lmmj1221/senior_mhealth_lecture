#!/bin/bash

# Deploy AI Service to Cloud Run with Vertex AI (Fixed)
# This script uses Vertex AI with proper region and model configuration

set -e

# Get project ID
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo "Error: GCP project not set. Run 'gcloud config set project YOUR_PROJECT_ID'"
    exit 1
fi

echo "Deploying AI Service to Cloud Run with Vertex AI..."
echo "Project: $PROJECT_ID"

# Deploy with Vertex AI configuration - using us-central1 which has better model support
gcloud run deploy senior-mhealth-ai \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v1 \
  --platform managed \
  --region asia-northeast3 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 5 \
  --allow-unauthenticated \
  --service-account=automation-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --set-env-vars="USE_VERTEX_AI=true,GOOGLE_CLOUD_PROJECT=${PROJECT_ID},VERTEX_AI_LOCATION=us-central1,MODEL_NAME=gemini-1.0-pro,ENVIRONMENT=production,PORT=8080"

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

echo ""
echo "📝 Notes:"
echo "- Using Vertex AI with us-central1 region (better model availability)"
echo "- Model: gemini-1.0-pro (most stable)"
echo "- USE_VERTEX_AI=true forces Vertex AI usage"