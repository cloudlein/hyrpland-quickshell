#!/usr/bin/env python3
import sys
import os
import json
import time
import subprocess

CACHE_DIR = os.path.expanduser("~/.cache")
HIST_FILE = os.path.join(CACHE_DIR, "quickshell_clipboard.json")
MAX_ITEMS = 60

def load_history():
    if not os.path.exists(HIST_FILE):
        return []
    try:
        with open(HIST_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []

def save_history(items):
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(HIST_FILE, "w", encoding="utf-8") as f:
        json.dump(items[:MAX_ITEMS], f, ensure_ascii=False, indent=2)

def record():
    try:
        content = sys.stdin.read()
    except Exception:
        return
    if not content or not content.strip():
        return
    
    items = load_history()
    # If same as latest, ignore
    if items and items[0].get("text") == content:
        return
    
    # Filter out existing duplicates so it bumps to the top
    items = [it for it in items if it.get("text") != content]
    
    entry = {
        "id": int(time.time() * 1000),
        "text": content,
        "preview": content.strip().replace("\n", " ")[:120],
        "lines": content.count("\n") + 1,
        "chars": len(content),
        "time": time.strftime("%H:%M")
    }
    items.insert(0, entry)
    save_history(items)

def list_items():
    items = load_history()
    print(json.dumps(items, ensure_ascii=False))

def delete_item(item_id):
    items = load_history()
    items = [it for it in items if str(it.get("id")) != str(item_id)]
    save_history(items)

def clear_all():
    save_history([])

def copy_item(item_id):
    items = load_history()
    for it in items:
        if str(it.get("id")) == str(item_id):
            p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
            p.communicate(input=it.get("text", "").encode("utf-8"))
            break

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd == "record":
        record()
    elif cmd == "list":
        list_items()
    elif cmd == "delete" and len(sys.argv) > 2:
        delete_item(sys.argv[2])
    elif cmd == "clear":
        clear_all()
    elif cmd == "copy" and len(sys.argv) > 2:
        copy_item(sys.argv[2])
