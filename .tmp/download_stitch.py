import os
import requests
import json

urls = {
    "19be37d12c414ba2865ebd8d0003fd16_main_desktop.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY0Y2ZkYzEzMDQwZjgwMzMyY2FkODA5MmMzZThkEgsSBxDQ0LrWlgMYAZIBIwoKcHJvamVjdF9pZBIVQhM1Njk4MTUyMjE5ODM4MDA4NzI1&filename=&opi=89354086",
    "7dcf493f619242b58bd99d20485df279_calendar_mobile.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY0Y2ZkYzEzMDQwZjcwMzMyY2FkODA5MmMzZThkEgsSBxDQ0LrWlgMYAZIBIwoKcHJvamVjdF9pZBIVQhM1Njk4MTUyMjE5ODM4MDA4NzI1&filename=&opi=89354086",
    "91bd0d9ab2c748c39839cadd312b95a1_technical_eval_mobile.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY0Y2ZkYzEzMDQwZmEwMzMyY2FkODA5MmMzZThkEgsSBxDQ0LrWlgMYAZIBIwoKcHJvamVjdF9pZBIVQhM1Njk4MTUyMjE5ODM4MDA4NzI1&filename=&opi=89354086",
    "ebcfcc12de0843a3a40b489e34032ad7_dashboard_athlete_mobile.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY0Y2ZkYzEzMDQwZmMwMzMyY2FkODA5MmMzZThkEgsSBxDQ0LrWlgMYAZIBIwoKcHJvamVjdF9pZBIVQhM1Njk4MTUyMjE5ODM4MDA4NzI1&filename=&opi=89354086",
    "fa1b60bbeebb4a7ea97d262273d6eee0_history_evolution_mobile.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY0Y2ZkYzEzMDQwZjMwMzMyY2FkODA5MmMzZThkEgsSBxDQ0LrWlgMYAZIBIwoKcHJvamVjdF9pZBIVQhM1Njk4MTUyMjE5ODM4MDA4NzI1&filename=&opi=89354086"
}

os.makedirs(r"c:\Antigravity\DCEP\stitch_imports", exist_ok=True)

for filename, url in urls.items():
    print(f"Downloading {filename}...")
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        with open(os.path.join(r"c:\Antigravity\DCEP\stitch_imports", filename), 'w', encoding='utf-8') as f:
            f.write(response.text)
        print(f"  -> Saved {filename}")
    except Exception as e:
        print(f"  -> Error: {e}")
