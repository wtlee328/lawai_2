#!/bin/bash

# GitHub Repository Setup Script for Lawai 2.0
# This script helps prepare your project for GitHub and Vercel deployment

echo "🚀 Lawai 2.0 GitHub Setup Script"
echo "=================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Please run 'git init' first."
    exit 1
fi

# Check if .env file exists and warn about it
if [ -f ".env" ]; then
    echo "⚠️  Warning: .env file detected"
    echo "   This file contains sensitive information and should NOT be committed to GitHub."
    echo "   Make sure .env is in your .gitignore file."
    
    if grep -q ".env" .gitignore; then
        echo "✅ .env is properly ignored in .gitignore"
    else
        echo "❌ .env is NOT in .gitignore. Adding it now..."
        echo ".env" >> .gitignore
    fi
fi

# Show current git status
echo "\n📋 Current Git Status:"
git status --short

# Ask for GitHub repository details
echo "\n🔧 GitHub Repository Setup"
echo "Please create a new repository on GitHub first, then provide the details:"
echo "\nRepository URL format: https://github.com/USERNAME/REPOSITORY_NAME.git"
read -p "Enter your GitHub repository URL: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "❌ Repository URL is required. Exiting."
    exit 1
fi

# Validate URL format
if [[ ! $REPO_URL =~ ^https://github\.com/.+/.+\.git$ ]]; then
    echo "❌ Invalid GitHub URL format. Expected: https://github.com/username/repo.git"
    exit 1
fi

echo "\n📦 Preparing repository..."

# Add all files
echo "Adding all files to git..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit."
else
    # Commit changes
    echo "Committing changes..."
    git commit -m "Initial commit: Lawai 2.0 with Hugging Face integration

- Vue.js frontend with TypeScript and Tailwind CSS
- Integrated with Hugging Face Python service
- Supabase database configuration
- Vercel deployment ready
- Environment variables properly configured"
fi

# Check if remote origin already exists
if git remote get-url origin >/dev/null 2>&1; then
    echo "⚠️  Remote origin already exists. Removing and adding new one..."
    git remote remove origin
fi

# Add remote origin
echo "Adding GitHub remote..."
git remote add origin "$REPO_URL"

# Set main branch and push
echo "Setting main branch and pushing to GitHub..."
git branch -M main

if git push -u origin main; then
    echo "\n🎉 Successfully pushed to GitHub!"
    echo "\n📋 Next Steps:"
    echo "1. Visit your GitHub repository: ${REPO_URL%.git}"
    echo "2. Verify all files are uploaded correctly"
    echo "3. Check that .env file is NOT visible (should be ignored)"
    echo "4. Proceed with Vercel deployment"
    
    echo "\n🚀 Vercel Deployment:"
    echo "1. Go to https://vercel.com"
    echo "2. Import your GitHub repository"
    echo "3. Set environment variables:"
    echo "   - VITE_PYTHON_API_URL=https://wtlee328-lawai-python-service.hf.space"
    echo "   - VITE_SUPABASE_URL=<your_supabase_url>"
    echo "   - VITE_SUPABASE_ANON_KEY=<your_supabase_key>"
    echo "4. Deploy!"
    
    echo "\n📖 For detailed instructions, see GITHUB_SETUP_GUIDE.md"
else
    echo "\n❌ Failed to push to GitHub. Please check:"
    echo "1. Repository URL is correct"
    echo "2. You have write access to the repository"
    echo "3. GitHub authentication is set up"
    echo "\nYou may need to authenticate with GitHub first:"
    echo "git config --global user.name 'Your Name'"
    echo "git config --global user.email 'your.email@example.com'"
fi

echo "\n✅ GitHub setup script completed!"