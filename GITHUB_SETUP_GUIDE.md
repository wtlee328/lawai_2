# GitHub Repository Setup Guide for Lawai 2.0

## 🚀 Step-by-Step Guide to Create GitHub Repository

### Step 1: Create GitHub Repository

1. **Go to GitHub**: Visit [github.com](https://github.com) and sign in
2. **Create New Repository**:
   - Click the "+" icon in the top right corner
   - Select "New repository"
   - Repository name: `lawai-2.0` (or your preferred name)
   - Description: `Lawai 2.0 - AI-powered legal case search and document generation platform`
   - Set to **Public** or **Private** (your choice)
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
   - Click "Create repository"

### Step 2: Prepare Local Repository

Run these commands in your terminal from the project directory:

```bash
# Add all files to git
git add .

# Commit all changes
git commit -m "Initial commit: Lawai 2.0 with Hugging Face integration"

# Add your GitHub repository as remote origin
# Replace YOUR_USERNAME and YOUR_REPO_NAME with actual values
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 3: Verify Repository

1. **Check GitHub**: Refresh your GitHub repository page
2. **Verify Files**: Ensure all project files are uploaded
3. **Check .env Protection**: Confirm that `.env` file is NOT visible (it should be ignored)

## 📋 Pre-Deployment Checklist

### ✅ Files Ready for GitHub
- [x] Source code (`src/` directory)
- [x] Configuration files (`package.json`, `vite.config.ts`, etc.)
- [x] Deployment configuration (`vercel.json`)
- [x] Documentation (`README.md`, `DEPLOYMENT_CHECKLIST.md`)
- [x] Environment example (`.env.example`)
- [x] Deployment script (`deploy.sh`)

### ⚠️ Files Excluded (Protected)
- [x] `.env` (contains sensitive keys)
- [x] `node_modules/` (will be installed during build)
- [x] `dist/` (build output)
- [x] Log files

## 🔧 Vercel Deployment Setup

### Option 1: Vercel Dashboard (Recommended)

1. **Go to Vercel**: Visit [vercel.com](https://vercel.com)
2. **Import Project**:
   - Click "New Project"
   - Import from GitHub
   - Select your `lawai-2.0` repository
3. **Configure Environment Variables**:
   ```
   VITE_PYTHON_API_URL=https://wtlee328-lawai-python-service.hf.space
   VITE_SUPABASE_URL=https://okovecmzacczvimjsxcd.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
4. **Deploy**: Click "Deploy"

### Option 2: Vercel CLI

```bash
# Install Vercel CLI (if not already installed)
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

## 🎯 Important Notes

### Environment Variables
- **Never commit `.env` file** to GitHub
- **Always set environment variables** in Vercel dashboard
- **Use `.env.example`** as a template for required variables

### Current Configuration
- **Frontend**: Vue.js + TypeScript + Tailwind CSS
- **Backend**: Hugging Face Space (Python service)
- **Database**: Supabase PostgreSQL
- **Deployment**: Vercel (frontend only)

### API Integration
- **Python Service**: `https://wtlee328-lawai-python-service.hf.space`
- **Search Endpoint**: `/new-search`
- **Health Check**: `/`

## 🔍 Troubleshooting

### Common Issues

1. **Environment Variables Not Working**:
   - Ensure all `VITE_` prefixed variables are set in Vercel
   - Redeploy after adding environment variables

2. **Build Failures**:
   - Check that all dependencies are in `package.json`
   - Verify TypeScript configuration

3. **API Connection Issues**:
   - Confirm Hugging Face Space is running
   - Check CORS configuration
   - Verify API URL is correct

## 📞 Next Steps

1. **Create GitHub Repository** (follow Step 1)
2. **Push Code to GitHub** (follow Step 2)
3. **Deploy to Vercel** (use Vercel dashboard)
4. **Test Production Deployment**
5. **Monitor and Optimize**

---

**Ready to Deploy!** 🚀

Your project is now configured to use Hugging Face Python service and ready for production deployment.