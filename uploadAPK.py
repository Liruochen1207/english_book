import base64
import requests

byte = None

with open(r"build\app\outputs\flutter-apk\app-release.apk", "rb") as f:
    byte = f.read()

version = "1.0.3"


content = base64.b64encode(byte).decode()
po = requests.post("http://47.108.91.180:5000/upload_apk", data = {"name":"base", "version":version, "content":content }).content.decode('utf-8')
    
print(po)
