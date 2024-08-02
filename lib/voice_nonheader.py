import base64
import os

from io import BytesIO
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
import pygame
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '0'
import requests


import json as JSON

headers01 = {}
headers02 = {}

header = """Accept: */*
Accept-Encoding: gzip, deflate, br
Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6
Connection: keep-alive
Content-Length: 64
Content-Type: application/x-www-form-urlencoded
Cookie: BIDUPSID=FCC6B603D43E89BC34CB8CAC2C78B2E4; PSTM=1658036488; BAIDUID=FCC6B603D43E89BC633DF295B19B6708:FG=1; BDORZ=B490B5EBF6F3CD402E515D22BCDA1598; BAIDUID_BFESS=FCC6B603D43E89BC633DF295B19B6708:FG=1; BA_HECTOR=818g25242k8580a12ga1a57s1i3csfm1n; ZFY=0q4BX3KaUO7mtRFC3p:AW84PPi86XkCONBkAVZqd1x94:C; __bid_n=18774322d28b02c8954207; RT="z=1&dm=baidu.com&si=a870fa27-e5d8-4326-a43f-6d0d28f8a58b&ss=lgdghncw&sl=0&tt=0&bcn=https%3A%2F%2Ffclog.baidu.com%2Flog%2Fweirwood%3Ftype%3Dperf&ld=1ihy&ul=6526t&hd=652aa"; BDRCVFR[feWj1Vr5u3D]=I67x6TjHwwYf0; PSINO=6; delPer=0; H_PS_PSSID=38516_36545_38470_38468_38486_37937_37709_26350_38186; BCLID=11843058899525825520; BCLID_BFESS=11843058899525825520; BDSFRCVID=SOIOJeC62mkJ3G3fb1tDMPjx3gJxjCOTH6aoa-VjV8foDiJ4u5pMEG0PKM8g0K4-S2aWogKKXgOTHw0F_2uxOjjg8UtVJeC6EG0Ptf8g0f5; BDSFRCVID_BFESS=SOIOJeC62mkJ3G3fb1tDMPjx3gJxjCOTH6aoa-VjV8foDiJ4u5pMEG0PKM8g0K4-S2aWogKKXgOTHw0F_2uxOjjg8UtVJeC6EG0Ptf8g0f5; H_BDCLCKID_SF=tRAOoCP5JKvHjjrP-trf5DCShUFsQMRAB2Q-5KL-aRvkhp0Rb4Ka5M0I0M6OJ-bZMIQm2MbdJJjoHj6KMlDWb44vMtCJ-6QjBmTxoUJcBCnJhhkmqq-K-q-ebPRiXPb9QgbfopQ7tt5W8ncFbT7l5hKpbt-q0x-jLTnhVn0M5DK0HPonHjDhD6JW3H; H_BDCLCKID_SF_BFESS=tRAOoCP5JKvHjjrP-trf5DCShUFsQMRAB2Q-5KL-aRvkhp0Rb4Ka5M0I0M6OJ-bZMIQm2MbdJJjoHj6KMlDWb44vMtCJ-6QjBmTxoUJcBCnJhhkmqq-K-q-ebPRiXPb9QgbfopQ7tt5W8ncFbT7l5hKpbt-q0x-jLTnhVn0M5DK0HPonHjDhD6JW3H; Hm_lvt_8b973192450250dd85b9011320b455ba=1681184981,1681370645; CAMPAIGN_TRACK=cp%3Aainsem%7Cpf%3Apc%7Cpp%3A878-chanpin-yuyinjishu%7Cpu%3Ayuyinhecheng-API%7Cci%3A%7Ckw%3A10524204; BDUSS=VY4T3Rwak1STzJjalpwMWZvMkpqcHpXaWhuRXZWWjNURG0tfmpMWmdGUEFPMTlrSUFBQUFBJCQAAAAAAQAAAAEAAAAmiRwOz8TStrLdMTIwNwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMCuN2TArjdkS; BDUSS_BFESS=VY4T3Rwak1STzJjalpwMWZvMkpqcHpXaWhuRXZWWjNURG0tfmpMWmdGUEFPMTlrSUFBQUFBJCQAAAAAAQAAAAEAAAAmiRwOz8TStrLdMTIwNwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMCuN2TArjdkS; publicai-sessionid=; Hm_lpvt_8b973192450250dd85b9011320b455ba=1681371022; ab_sr=1.0.1_NzMwODYyMGVhMjhhOTFlYTZkNjUzNjhjODNhZGQyYmFmYmYzMDE4YmY4MWRiZWU1NzZkNTZkOWY4MGIxZDNjNzFlYjUwOWEzNmFjYjcxN2FhMzZhMDYzZGE2NWE1ZjRhMzNkNjE1ZWZhMzgyNzdkYjdmMjlkYTA3YzI0NzRlNzA5YzRmNjg2OTg4YzI2NmIzZTljNmUyNDIzNjA1ODk5NA==
Host: ai.baidu.com
Origin: https://ai.baidu.com
Referer: https://ai.baidu.com/tech/speech/tts_online
sec-ch-ua: "Chromium";v="112", "Microsoft Edge";v="112", "Not:A-Brand";v="99"
sec-ch-ua-mobile: ?0
sec-ch-ua-platform: "Windows"
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: cors
Sec-Fetch-Site: same-origin
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.39"""

class Voice:
    def __init__(self, text, play=True):
        self.text = text
        self.per = 4100
        self.spd = 5
        self.pit = 4
        self.vol = 4
        self.aue = 6
        if play:
            self.play()

    def play(self):
        text = self.text
        json = {'type': 'tns', 'per': self.per, 'spd': self.spd, 'pit': self.pit, 'vol': self.vol, 'aue': self.aue, 'tex': text}

        for hs in header.split("\n"):
            h = hs.split(": ")
            headers01[h[0]] = h[1]
        # with open("headers_new.txt", "r") as f:
        #     for hs in f.read().split("\n"):
        #         h = hs.split(": ")
        #         headers02[h[0]] = h[1]

        r2 = requests.post(f"https://ai.baidu.com/aidemo?type=tns&per={self.per}&spd={self.spd}&pit={self.pit}&vol={self.vol}&aue={self.aue}&tex={text}",
                           headers=headers01, json=json)

        get = JSON.loads(r2.content.decode())
        # print(get)
        mp3_content = base64.b64decode(get['data'].split(",")[1])

        # with open("play_sound.mp3", "wb") as f:
        #     f.write(mp3_content)
        # os.system("start play_sound.mp3")

        audio_bytes = BytesIO(mp3_content)
        pygame.init()
        pygame.mixer.music.load(audio_bytes)
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            pygame.time.Clock().tick(10)
        pygame.quit()

if __name__ == "__main__":
    print("输入文字，然后按回车")
    while True:
        Voice(input("> "))
