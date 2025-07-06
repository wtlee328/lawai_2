#!/bin/bash

# Deployment script for Lawai 2.0 to Vercel
# This script helps ensure all configurations are correct before deployment

echo "🚀 Lawai 2.0 Deployment Script"
echo "=============================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Vercel CLI not found. Installing..."
    npm install -g vercel
fi

# Verify environment variables
echo "\n🔍 Checking environment variables..."
if [ -f ".env" ]; then
    echo "✅ .env file found"
    
    # Check for required variables
    if grep -q "VITE_PYTHON_API_URL=https://wtlee328-lawai-python-service.hf.space" .env; then
        echo "✅ Python API URL correctly set to Hugging Face Space"
    else
        echo "❌ Warning: VITE_PYTHON_API_URL may not be set correctly"
        echo "   Expected: https://wtlee328-lawai-python-service.hf.space"
        echo "   Current: $(grep VITE_PYTHON_API_URL .env || echo 'Not found')"
    fi
    
    if grep -q "SUPABASE_URL" .env; then
        echo "✅ Supabase URL found"
    else
        echo "❌ Warning: SUPABASE_URL not found in .env"
    fi
else
    echo "❌ Warning: .env file not found"
fi

# Run tests
echo "\n🧪 Running integration tests..."
if node test_frontend_integration.js; then
    echo "✅ All integration tests passed"
else
    echo "❌ Integration tests failed. Please fix issues before deploying."
    exit 1
fi

# Build the project
echo "\n🔨 Building project..."
if npm run build; then
    echo "✅ Build successful"
else
    echo "❌ Build failed. Please fix build errors before deploying."
    exit 1
fi

# Deploy to Vercel
echo "\n🚀 Deploying to Vercel..."
echo "\n⚠️  Important: Make sure you have set the following environment variables in your Vercel dashboard:"
echo "   - VITE_PYTHON_API_URL=https://wtlee328-lawai-python-service.hf.space"
echo "   - VITE_SUPABASE_URL=<your_supabase_url>"
echo "   - VITE_SUPABASE_ANON_KEY=<your_supabase_anon_key>"
echo "\nPress Enter to continue with deployment, or Ctrl+C to cancel..."
read -r

# Deploy
if vercel --prod; then
    echo "\n🎉 Deployment successful!"
    echo "\n📋 Post-deployment checklist:"
    echo "   1. Test the search functionality on your live site"
    echo "   2. Check browser console for any errors"
    echo "   3. Verify API calls to Hugging Face service are working"
    echo "   4. Test user authentication and workspace features"
else
    echo "\n❌ Deployment failed. Please check the error messages above."
    exit 1
fi

echo "\n✅ Deployment process completed!"