import requests
import json

url = "https://stitch.googleapis.com/mcp"
api_key = "AQ.Ab8RN6KDnON1i9bao5Rw00439rngeD4a242PKfhIol9Ew2tSRg"
headers = {"X-Goog-Api-Key": api_key}

try:
    # Test if it's an SSE endpoint - typically SSE would return a stream or a 405/404 if not accessed correctly
    # But let's check a basic GET or POST
    response = requests.get(url, headers=headers, timeout=10)
    print(f"Status: {response.status_code}")
    print(f"Content: {response.text[:200]}")
except Exception as e:
    print(f"Error: {e}")
