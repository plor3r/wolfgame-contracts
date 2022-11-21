from pathlib import Path
import json
data = {}
for a in Path('traits_data').iterdir():
    t = list(map(int, a.name.rstrip('.json').split("_")))
    if t[0] not in data:
        data[t[0]] = {}
    if t[1] not in data[t[0]]:
        data[t[0]][t[1]] = {}
    data[t[0]][t[1]] = json.load(open(a))
# print(data)

for i in range(18):
    print(f"""
        upload_traits({i}, vector<u8>[""" + ",".join([str(k) for k in range(len(data[i]))]) + """], vector[\n            """ +
    ",\n            ".join(['Trait { name: string::utf8(b"' + data[i][j]["name"] + '"), png: string::utf8(b"' + data[i][j]["png"] + '")}''' for j in data[i]])
            + """\n        ]);
    """)