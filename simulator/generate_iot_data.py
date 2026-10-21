
# Each record will be written as JSON Lines
import json 

# Generate random numbers through seed
import random 

# Where each event have a unique event_id
import uuid 

#for passing the data through the command line
import argparse 

from datetime import datetime, timedelta, timezone 
from pathlib import Path

START = datetime(2026, 1, 1, tzinfo=timezone.utc) #UTC time zone
N_MACHINES, INTERVAL_MIN = 20, 5

def build_fleet(seed=42):
    rng = random.Random(seed) # Independent generator with fixed seed, everytime we run the code we will get the same fleet
    fleet = []
    for i in range(N_MACHINES):
        fails = rng.random() < 0.35 # 35% of machines will fail once, which gives us a majority of normal machines and a minority that has degradation signals
        fleet.append({
            "machine_id": f"M{i:04d}",
            "machine_type": rng.choice(["PUMP", "COMPRESSOR", "MOTOR"]),
            "plant_id": rng.choice(["PLANT_A", "PLANT_B", "PLANT_C"]),
            "criticality": rng.choice(["LOW", "MEDIUM", "HIGH"]), # equipment criticality
            "install_date": (START - timedelta(days=rng.randint(200,3000))).date().isoformat(),
            "base_temp": rng.uniform(55, 75),
            "base_vib": rng.uniform(0.8, 1.6),
            "fail_dt": START + timedelta(hours=rng.randint(120, 2490)) if fails else None,
        })
    return fleet    


def reading(m, ts, rng):
    deg = 0.0 # between 0 and 1, how much the equipment is failing currently 
    if m["fail_dt"] and ts < m["fail_dt"]:
        hrs_left = (m["fail_dt"] - ts).total_seconds() / 3600
        deg = max(0.0, 1 - hrs_left / 72) ** 2 # ramps up in final 72h, predictive horizon = 72h
        # Seventy-two hours (3 days) before failure, we begin to increase the degree 
        # It starts at 0 and increases as we approach failure > reaching 1 at the moment of failure
        # Then, the deterioration accelerates as the end approaches (and this is very realistic, the engine heats up rapidly before it fails)

    row = {
        "event_id": str(uuid.uuid4()),
        "machine_id": m["machine_id"],
        "event_ts": ts.isoformat().replace("+00:00", "Z"),
        "temperature_c": round(m["base_temp"] + 30 * deg + rng.gauss(0, 1.2), 2),
        "vibration_mm_s": round(m["base_vib"] + (12.5 * deg) + rng.gauss(0, 0.05), 3),
        "pressure_kpa": round(rng.gauss(850, 15), 1),
        "rpm": round(rng.gauss(1480, 12), 0),
        "current_a": round(rng.gauss(42, 1.5) + (10.3 * deg), 2),
        "ingest_ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }    # when deg = 0 the readings are normal, but when deg = 1 the temp  
         # will increase to 30 and the viberation increase 12.5mm/s
         # thse relationships are the signals that the model should detect
         # each field has gaussian noise so that the data won't be mathematically perfect

    # Schema Evolution: We test whether the pipeline handles new fields that appear unexpectedly   
    if ts > START + timedelta(days=30): # schema drift: new field appears later
        row["firmware_version"] = "2.1.0"
        # before 30 days of START, there is no firmware version
        # after it, the field will appear      

    r =  rng.random() # inject data-quality defects
    if r < 0.005: 
         row["temperature_c"] = None  # missing value
    elif r < 0.007:
         row["temperature_c"] = 999.0  # sensor glitch / outlier
    return row     
    # 0.5% of the readings contain null values
    # An additional 0.2% contain an impossible value (999°C) 
    # Total: 0.7% "dirty" data.
    # Goal: Test the Data Quality stage in the pipeline (imputation/filtering)

def main(date_str, out="out/bronze/iot_sensor"):
    rng = random.Random(date_str)
    day = datetime.fromisoformat(date_str).replace(tzinfo=timezone.utc)    

    for hr in range(24):
        rows = []
        for m in build_fleet():
            for k in range(60 // INTERVAL_MIN):
                ts = day + timedelta(hours=hr, minutes=k * INTERVAL_MIN)
                row = reading(m, ts, rng)
                rows.append(row)
                if rng.random() < 0.01:
                    rows.append(dict(row))  # duplicate delivery
    # 24 hours × 12 readings/hour (every 5 minutes) × 20 pieces of equipment = 5,760 readings per day.  
        d = Path(out) / f"dt={date_str}" / f"hr={hr:02d}"
        d.mkdir(parents=True, exist_ok=True)
        (d / "part-0000.json").write_text("\n".join(json.dumps(r) for r in rows))
    print(f"Successfully generated IoT data for date: {date_str}")      

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", required=True)
    main(ap.parse_args().date)


      





