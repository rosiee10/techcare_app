"""
Centralized logging configuration for TechCare backend.
Provides structured logging with proper error handling.
"""

import logging
import sys
from pathlib import Path

# Create logs directory if it doesn't exist
LOGS_DIR = Path(__file__).resolve().parent.parent / 'logs'
LOGS_DIR.mkdir(exist_ok=True)

# Configure logging format
LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'

def get_logger(name: str) -> logging.Logger:
    """
    Get a configured logger instance.
    
    Args:
        name: Name of the logger (typically __name__ of the module)
        
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    
    # Only configure if not already configured
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        
        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
        console_handler.setFormatter(console_formatter)
        
        # File handler for errors
        error_file_handler = logging.FileHandler(LOGS_DIR / 'error.log')
        error_file_handler.setLevel(logging.ERROR)
        error_formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
        error_file_handler.setFormatter(error_formatter)
        
        # File handler for all logs
        info_file_handler = logging.FileHandler(LOGS_DIR / 'info.log')
        info_file_handler.setLevel(logging.INFO)
        info_formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
        info_file_handler.setFormatter(info_formatter)
        
        logger.addHandler(console_handler)
        logger.addHandler(error_file_handler)
        logger.addHandler(info_file_handler)
    
    return logger
