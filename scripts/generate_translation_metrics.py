#!/usr/bin/env python3
import requests
import json
import os

OUTPUT_DIR = "data"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "translations_metrics.json")

COMPONENT_TRANSLATIONS_URL = "https://hosted.weblate.org/api/components/planner/io-github-alainm23-planify/translations/"

def fetch_translations():
    metrics = {}
    page = 1

    while True:
        url = f"{COMPONENT_TRANSLATIONS_URL}?page={page}"
        response = requests.get(url)
        if response.status_code != 200:
            print(f"Error fetching Weblate data: {response.status_code}")
            break

        data = response.json()
        for item in data.get("results", []):
            lang = item["language_code"]
            metrics[lang] = {
                "language": item["language"]["name"],
                "total_strings": item["total"],
                "translated_strings": item["translated"],
                "translated_percent": item["translated_percent"]
            }

        if not data.get("next"):
            break
        page += 1

    return metrics

def save_metrics(metrics):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2, ensure_ascii=False)
    print(f"File '{OUTPUT_FILE}' updated ✅")

def main():
    metrics = fetch_translations()
    save_metrics(metrics)

if __name__ == "__main__":
    main()
