# LawAI 2.0 Python Service

This directory contains the Python backend services for the legal case search system.

## Directory Structure

```
python_service/
├── search_service/          # Core search functionality
│   ├── main.py             # FastAPI application
│   ├── law_case_search.py  # Original search service
│   └── law_case_search_2.py # Enhanced search service
├── ingestion/              # Data ingestion scripts
│   ├── memory_optimized_ingest.py    # Recommended ingestion script
│   ├── ingest_embeddings_to_supabase.py
│   ├── clear_supabase_table.py
│   └── run_embedding_and_ingest.py
├── optimization_tools/     # Embedding optimization tools
│   ├── fast_optimize_embeddings.py   # Recommended optimization
│   ├── optimize_embeddings.py
│   ├── final_cleanup.py
│   └── verify_optimization.py
├── utilities/              # Analysis and reporting tools
│   ├── quick_embedding_status.py
│   ├── generate_embedding_report.py
│   └── optimization_summary.py
├── tests/                  # Test files
│   ├── test_unit_core_components.py
│   ├── test_integration_comprehensive.py
│   └── test_performance_quality.py
└── embedding_generation/   # Core embedding generation system
    ├── main_controller.py  # Main embedding controller
    ├── multi_field_generator.py
    ├── config.py
    └── ... (other core modules)
```

## Quick Start

### 1. Search Service
```bash
cd search_service
python main.py
```

### 2. Embedding Generation
```bash
cd embedding_generation
python main_controller.py
```

### 3. Optimization (if needed)
```bash
cd optimization_tools
python fast_optimize_embeddings.py
```

### 4. Ingestion
```bash
cd ingestion
python memory_optimized_ingest.py
```

## Environment Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set environment variables:
```bash
export SUPABASE_URL="your_supabase_url"
export SUPABASE_SERVICE_KEY="your_service_key"
export OPENAI_API_KEY="your_openai_key"
```

## Core Workflows

### Embedding Generation Workflow
1. Run embedding generation: `embedding_generation/main_controller.py`
2. Optimize embeddings: `optimization_tools/fast_optimize_embeddings.py`
3. Ingest to database: `ingestion/memory_optimized_ingest.py`

### Search Service Workflow
1. Start search service: `search_service/main.py`
2. Access API at `http://localhost:8000`

## Features

- **Legal Case Search**: Advanced search functionality with multiple search methods
- **Embedding Generation**: Multi-field embedding generation with quality assurance
- **Memory-Optimized Ingestion**: Efficient data ingestion for large datasets
- **Optimization Tools**: Tools to reduce embedding file sizes
- **Real-time Monitoring**: Progress tracking and performance metrics

## API Endpoints

### Health Check
- `GET /` - Returns service status

### Search Endpoints
- `POST /new-search` - Knowledge base search with multiple search methods

### WebSocket
- `WS /ws/log` - Real-time logging stream

## Environment Variables

- `OPENAI_API_KEY` - OpenAI API key
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_KEY` - Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key
- `ALLOWED_ORIGINS` - Comma-separated list of allowed CORS origins
- `PORT` - Port number (defaults to 7860 for Hugging Face)

## Documentation

Each directory contains its own README.md with specific usage instructions:

- [Search Service](search_service/README.md)
- [Ingestion](ingestion/README.md)
- [Optimization Tools](optimization_tools/README.md)
- [Utilities](utilities/README.md)
- [Tests](tests/README.md)
- [Embedding Generation](embedding_generation/README.md)

## Security

- Runs as non-root user
- Environment variables for sensitive data
- CORS configuration for secure frontend integration
- Health checks for monitoring