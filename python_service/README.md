---
title: LawAI 2.0 Python Service
emoji: ⚖️
colorFrom: blue
colorTo: purple
sdk: docker
app_port: 7860
---

# LawAI 2.0 Python Service

This is the backend API service for LawAI 2.0, providing legal case search capabilities.

## Features

- **Legal Case Search**: Advanced search functionality with multiple search methods
- **Real-time Logging**: WebSocket-based logging for real-time monitoring
- **CORS Support**: Configurable CORS for frontend integration

## API Endpoints

### Health Check
- `GET /` - Returns service status

### Search Endpoints
- `POST /new-search` - Knowledge base search with multiple search methods

### WebSocket
- `WS /ws/log` - Real-time logging stream

## Environment Variables

The following environment variables need to be configured in Hugging Face Spaces:

- `OPENAI_API_KEY` - OpenAI API key
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_KEY` - Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key
- `ALLOWED_ORIGINS` - Comma-separated list of allowed CORS origins
- `PORT` - Port number (defaults to 7860 for Hugging Face)

## Deployment

This service is containerized and ready for deployment on Hugging Face Spaces. The Docker configuration automatically:

- Installs all required dependencies
- Sets up a non-root user for security
- Configures health checks
- Exposes the service on port 7860

## Usage

Once deployed, the service will be available at your Hugging Face Space URL. You can integrate it with your frontend by updating the API base URL to point to your deployed service.

## Security

- Runs as non-root user
- Environment variables for sensitive data
- CORS configuration for secure frontend integration
- Health checks for monitoring