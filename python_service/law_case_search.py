#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Law Case Search Service

This module provides search functionality for law cases stored in Supabase database.
It supports semantic search using embeddings and keyword-based search.
"""

import os
import logging
from typing import List, Dict, Any, Optional
from supabase import create_client, Client
import openai
from datetime import datetime

logger = logging.getLogger(__name__)

class LawCaseSearchService:
    """Service for searching law cases in Supabase database"""
    
    def __init__(self):
        # Initialize Supabase client
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_KEY')
        
        if not supabase_url or not supabase_key:
            raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
        
        self.supabase: Client = create_client(supabase_url, supabase_key)
        
        # Initialize OpenAI for embeddings
        openai_api_key = os.getenv('OPENAI_API_KEY')
        if openai_api_key:
            openai.api_key = openai_api_key
            self.has_openai = True
        else:
            self.has_openai = False
            logger.warning("OpenAI API key not found - semantic search will be disabled")
    
    def _extract_court_from_case_id(self, case_id: str) -> str:
        """Extract court name from case_id"""
        try:
            # Case ID format is typically like "70年度台上字第1615號民事"
            if '台上' in case_id:
                return '最高法院'
            elif '台高' in case_id:
                return '台灣高等法院'
            elif '台中高' in case_id:
                return '台灣高等法院台中分院'
            elif '台南高' in case_id:
                return '台灣高等法院台南分院'
            elif '高雄高' in case_id:
                return '台灣高等法院高雄分院'
            elif '花蓮高' in case_id:
                return '台灣高等法院花蓮分院'
            elif '台北地' in case_id:
                return '台灣台北地方法院'
            elif '新北地' in case_id:
                return '台灣新北地方法院'
            elif '桃園地' in case_id:
                return '台灣桃園地方法院'
            elif '台中地' in case_id:
                return '台灣台中地方法院'
            elif '台南地' in case_id:
                return '台灣台南地方法院'
            elif '高雄地' in case_id:
                return '台灣高雄地方法院'
            else:
                return '最高法院'  # Default fallback
        except Exception:
            return '最高法院'  # Default fallback
    
    def _get_embedding(self, text: str) -> Optional[List[float]]:
        """Generate embedding for text using OpenAI"""
        if not self.has_openai:
            return None
        
        try:
            response = openai.embeddings.create(
                model="text-embedding-ada-002",
                input=text
            )
            return response.data[0].embedding
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return None
    
    def semantic_search(self, query: str, limit: int = 10, threshold: float = 0.7) -> List[Dict[str, Any]]:
        """Perform semantic search using embeddings"""
        if not self.has_openai:
            logger.warning("Semantic search not available - OpenAI API key not configured")
            return []
        
        # Generate embedding for query
        query_embedding = self._get_embedding(query)
        if not query_embedding:
            return []
        
        try:
            # Use the match_cases function from the database
            result = self.supabase.rpc('match_cases', {
                'query_embedding': query_embedding,
                'match_threshold': threshold,
                'match_count': limit
            }).execute()
            
            cases = []
            for row in result.data:
                cases.append({
                    'case_id': row['case_id'],
                    'title': row['case_id'],  # Always use case_id as title
                    'case_topic': row['case_topic'],  # Keep original for compatibility
                    'date_decided': row['case_date'],
                    'case_date': row['case_date'],  # Keep original for compatibility
                    'summary': row['case_gist'],
                    'case_gist': row['case_gist'],  # Keep original for compatibility
                    'court': self._extract_court_from_case_id(row['case_id']),
                    'relevance_score': row['similarity'],
                    'search_method': 'semantic'
                })
            
            return cases
            
        except Exception as e:
            logger.error(f"Error in semantic search: {e}")
            return []
    
    def keyword_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform keyword-based search"""
        try:
            # Search in case topics and gists
            result = self.supabase.table('cases').select(
                'case_id, case_topic, case_date, case_gist'
            ).or_(
                f'case_topic.ilike.%{query}%,case_gist.ilike.%{query}%'
            ).limit(limit).execute()
            
            cases = []
            for row in result.data:
                cases.append({
                    'case_id': row['case_id'],
                    'title': row['case_id'],  # Always use case_id as title
                    'case_topic': row['case_topic'],  # Keep original for compatibility
                    'date_decided': row['case_date'],
                    'case_date': row['case_date'],  # Keep original for compatibility
                    'summary': row['case_gist'],
                    'case_gist': row['case_gist'],  # Keep original for compatibility
                    'court': self._extract_court_from_case_id(row['case_id']),
                    'relevance_score': 0.8,  # Default score for keyword matches
                    'search_method': 'keyword'
                })
            
            return cases
            
        except Exception as e:
            logger.error(f"Error in keyword search: {e}")
            return []
    
    def category_search(self, category: str, subcategory: str = None, limit: int = 10) -> List[Dict[str, Any]]:
        """Search cases by category and optionally subcategory"""
        try:
            query = self.supabase.table('cases').select(
                'case_id, case_topic, case_date, case_gist'
            ).join(
                'case_subcategory_mapping', 'cases.case_id', 'case_subcategory_mapping.case_id'
            ).join(
                'subcategories', 'case_subcategory_mapping.subcategory_id', 'subcategories.subcategory_id'
            ).join(
                'categories', 'subcategories.category_id', 'categories.category_id'
            ).eq('categories.category_name', category)
            
            if subcategory:
                query = query.eq('subcategories.subcategory_name', subcategory)
            
            result = query.limit(limit).execute()
            
            cases = []
            for row in result.data:
                cases.append({
                    'case_id': row['case_id'],
                    'title': row['case_id'],  # Always use case_id as title
                    'case_topic': row['case_topic'],  # Keep original for compatibility
                    'date_decided': row['case_date'],
                    'case_date': row['case_date'],  # Keep original for compatibility
                    'summary': row['case_gist'],
                    'case_gist': row['case_gist'],  # Keep original for compatibility
                    'court': self._extract_court_from_case_id(row['case_id']),
                    'relevance_score': 0.9,  # High score for category matches
                    'search_method': 'category'
                })
            
            return cases
            
        except Exception as e:
            logger.error(f"Error in category search: {e}")
            return []
    
    def hybrid_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform hybrid search combining semantic and keyword search"""
        all_results = []
        
        # Semantic search (if available)
        if self.has_openai:
            semantic_results = self.semantic_search(query, limit // 2)
            all_results.extend(semantic_results)
        
        # Keyword search
        keyword_results = self.keyword_search(query, limit // 2)
        all_results.extend(keyword_results)
        
        # Remove duplicates based on case_id
        seen_ids = set()
        unique_results = []
        for result in all_results:
            if result['case_id'] not in seen_ids:
                seen_ids.add(result['case_id'])
                unique_results.append(result)
        
        # Sort by relevance score
        unique_results.sort(key=lambda x: x['relevance_score'], reverse=True)
        
        return unique_results[:limit]
    
    def search(self, query: str, search_methods: List[str] = None, 
              filters: Dict[str, Any] = None, limit: int = 10) -> Dict[str, Any]:
        """Main search function that supports multiple search methods"""
        if search_methods is None:
            search_methods = ['hybrid']
        
        if filters is None:
            filters = {}
        
        all_results = []
        
        for method in search_methods:
            if method == 'semantic':
                results = self.semantic_search(query, limit)
            elif method == 'keyword':
                results = self.keyword_search(query, limit)
            elif method == 'category':
                category = filters.get('category')
                subcategory = filters.get('subcategory')
                if category:
                    results = self.category_search(category, subcategory, limit)
                else:
                    results = []
            elif method == 'hybrid':
                results = self.hybrid_search(query, limit)
            else:
                logger.warning(f"Unknown search method: {method}")
                results = []
            
            all_results.extend(results)
        
        # Remove duplicates and sort
        seen_ids = set()
        unique_results = []
        for result in all_results:
            if result['case_id'] not in seen_ids:
                seen_ids.add(result['case_id'])
                unique_results.append(result)
        
        unique_results.sort(key=lambda x: x['relevance_score'], reverse=True)
        final_results = unique_results[:limit]
        
        return {
            'success': True,
            'results': final_results,
            'total_count': len(final_results),
            'query': query,
            'search_methods': search_methods,
            'timestamp': datetime.now().isoformat()
        }