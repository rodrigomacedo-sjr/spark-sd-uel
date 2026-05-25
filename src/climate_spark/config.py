from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
SAMPLE_DIR = DATA_DIR / "sample"
OUTPUT_DIR = PROJECT_ROOT / "output"

TEMPERATURE_CITY_FILE = "GlobalLandTemperaturesByCity.csv"
GLOBAL_TEMPERATURE_FILE = "GlobalTemperatures.csv"
CO2_FILE = "owid-co2-data.csv"

COUNTRY_RENAMES = {
    "usa": "United States",
    "united states": "United States",
    "united states of america": "United States",
    "uk": "United Kingdom",
    "russia": "Russia",
}

CONTINENT_BY_COUNTRY = {
    "Australia": "Oceania",
    "Brazil": "South America",
    "China": "Asia",
    "Egypt": "Africa",
    "France": "Europe",
    "India": "Asia",
    "South Africa": "Africa",
    "United Kingdom": "Europe",
    "United States": "North America",
}

GLOBAL_AGGREGATES = {
    "Africa",
    "Asia",
    "Europe",
    "European Union (27)",
    "High-income countries",
    "International transport",
    "Low-income countries",
    "Lower-middle-income countries",
    "North America",
    "Oceania",
    "South America",
    "Upper-middle-income countries",
    "World",
}
