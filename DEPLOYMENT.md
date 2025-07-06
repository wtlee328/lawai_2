# LawAI 2.0 Cloud Deployment Guide

This guide walks you through deploying LawAI 2.0 to the cloud using Hugging Face Spaces for the Python backend and Vercel for the frontend.

## Architecture Overview

- **Backend**: Python FastAPI service deployed on Hugging Face Spaces
- **Frontend**: Vue.js application deployed on Vercel
- **Database**: Supabase (already cloud-hosted)

## Phase 1: Deploy Python Backend to Hugging Face Spaces

### Step 1: Prepare the Backend

The backend is already containerized and ready for deployment. The following files have been created:

- `python_service/Dockerfile` - Container configuration
- `python_service/.dockerignore` - Excludes unnecessary files
- `python_service/README.md` - Hugging Face Space configuration

### Step 2: Create Hugging Face Space

1. Go to [Hugging Face Spaces](https://huggingface.co/spaces)
2. Click "Create new Space"
3. Configure your space:
   - **Space name**: `lawai-2-python-service` (or your preferred name)
   - **License**: Apache 2.0
   - **SDK**: Docker
   - **Hardware**: CPU basic (upgrade if needed)

### Step 3: Upload Backend Code

1. Clone your new space repository:
   ```bash
   git clone https://huggingface.co/spaces/YOUR_USERNAME/lawai-2-python-service
   cd lawai-2-python-service
   ```

2. Copy the Python service files:
   ```bash
   cp -r /path/to/lawai_2.0/python_service/* .
   ```

3. Commit and push:
   ```bash
   git add .
   git commit -m "Initial deployment of LawAI 2.0 Python service"
   git push
   ```

### Step 4: Configure Environment Variables

In your Hugging Face Space settings, add these environment variables:

- `OPENAI_API_KEY`: Your OpenAI API key
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key
- `ALLOWED_ORIGINS`: Your Vercel domain (e.g., `https://your-app.vercel.app`)
- `PORT`: `7860` (Hugging Face default)

### Step 5: Test the Deployment

Once deployed, your API will be available at:
`https://YOUR_USERNAME-lawai-2-python-service.hf.space`

Test the health endpoint:
```bash
curl https://YOUR_USERNAME-lawai-2-python-service.hf.space/
```

## Phase 2: Deploy Frontend to Vercel

### Step 1: Prepare the Frontend

The frontend has been updated with:
- Environment variable configuration for API URL
- Vercel deployment configuration (`vercel.json`)

### Step 2: Deploy to Vercel

1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```

2. Login to Vercel:
   ```bash
   vercel login
   ```

3. Deploy from the project root:
   ```bash
   cd /path/to/lawai_2.0
   vercel
   ```

4. Follow the prompts:
   - Link to existing project or create new
   - Confirm settings

### Step 3: Configure Environment Variables in Vercel

In your Vercel dashboard, add these environment variables:

- `VITE_SUPABASE_URL`: Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY`: Your Supabase anon key
- `VITE_PYTHON_API_URL`: Your Hugging Face Space URL (e.g., `https://YOUR_USERNAME-lawai-2-python-service.hf.space`)

### Step 4: Update CORS Configuration

Update the `ALLOWED_ORIGINS` environment variable in your Hugging Face Space to include your Vercel domain:
```
https://your-app.vercel.app,http://localhost:5173
```

### Step 5: Test the Full Application

1. Visit your Vercel deployment URL
2. Test the search functionality
3. Verify API calls are working correctly

## Phase 3: Production Optimizations

### Backend Optimizations

1. **Upgrade Hardware**: Consider upgrading to CPU or GPU instances on Hugging Face for better performance
2. **Add Monitoring**: Implement health checks and logging
3. **Rate Limiting**: Add rate limiting for API endpoints
4. **Caching**: Implement Redis caching for search results

### Frontend Optimizations

1. **Custom Domain**: Add a custom domain in Vercel
2. **Performance**: Enable Vercel's Edge Functions if needed
3. **Analytics**: Add Vercel Analytics
4. **Error Tracking**: Implement error tracking (e.g., Sentry)

## Environment Variables Summary

### Hugging Face Spaces
```
OPENAI_API_KEY=your-openai-key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
ALLOWED_ORIGINS=https://your-app.vercel.app,http://localhost:5173
PORT=7860
```

### Vercel
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
VITE_PYTHON_API_URL=https://your-username-lawai-2-python-service.hf.space
```

## Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure `ALLOWED_ORIGINS` includes your Vercel domain
2. **API Connection**: Verify the `VITE_PYTHON_API_URL` is correct
3. **Build Failures**: Check environment variables are properly set
4. **Database Connection**: Verify Supabase credentials

### Monitoring

- **Hugging Face**: Check Space logs for backend issues
- **Vercel**: Use Vercel dashboard for frontend monitoring
- **Supabase**: Monitor database performance in Supabase dashboard

## Next Steps

After successful deployment:

1. Set up monitoring and alerting
2. Implement backup strategies
3. Consider CDN for static assets
4. Plan for scaling based on usage
5. Set up CI/CD pipelines for automated deployments

## Support

For issues:
- Check the logs in respective platforms
- Verify environment variables
- Test API endpoints individually
- Ensure all services are running