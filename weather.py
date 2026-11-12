import os
import requests

#APIKEY
API_KEY = os.getenv("OPENWEATHER_API_KEY", "")

url = "https://api.openweathermap.org/data/2.5/weather"
params = {
    "lat":44.34,
    "lon": 10.99,
    "appid": API_KEY,
    "units": "metric"
}

response = requests.get(url,params=params, timeout=10)
print(response)
data = response.json()
print(data)
