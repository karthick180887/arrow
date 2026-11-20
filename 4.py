from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import pandas as pd
from pydantic import BaseModel, Field, ValidationError

RAW_CUSTOMERS_PATH = Path("data/customers_raw.csv")
RAW_USAGE_PATH = Path("data/usage_events.json")
CORRUPTED_PATH = Path("data/customers_corrupted_batch.csv")
