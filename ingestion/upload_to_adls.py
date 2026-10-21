from azure.storage.blob import BlobServiceClient
import os
import argparse
import pathlib

from dotenv import load_dotenv

load_dotenv()

ap = argparse.ArgumentParser()
ap.add_argument("--date", required=True)
a = ap.parse_args()

connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
if not connection_string:
    raise SystemExit("Error: AZURE_STORAGE_CONNECTION_STRING is not set in environment or .env file")

svc = BlobServiceClient.from_connection_string(connection_string)
cont = svc.get_container_client("bronze")

for f in pathlib.Path(f"out/bronze/iot_sensor/dt={a.date}").rglob("*.json"):
    blob = f"iot_sensor/{f.relative_to('out/bronze/iot_sensor')}".replace("\\","/")
    with open(f, "rb") as fh:
        cont.upload_blob(blob, fh, overwrite=True) #overwrite = safe to rerun

print(f"Successfully uploaded data for date: {a.date} to Azure ADLS (Bronze) securely.")

