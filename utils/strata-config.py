import json
import os
from pathlib import Path

config_path = Path("/opt/lemonade/.cache/lemonade/config.json")
seed_path = Path("/opt/strata-config.json")

with config_path.open() as config_file, seed_path.open() as seed_file:
    config = json.load(config_file)
    strata = json.load(seed_file)["strata"]

config.setdefault("strata", {}).update(strata)
temporary_path = config_path.with_suffix(".json.tmp")
with temporary_path.open("w") as config_file:
    json.dump(config, config_file, indent=2)
    config_file.write("\n")
os.replace(temporary_path, config_path)
