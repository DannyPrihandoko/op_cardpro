import subprocess
import shutil
import sys
import os
from pathlib import Path

# Ensure UTF-8 output encoding for Windows terminal
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Target sets to scrape
targets = ["PRB-02"] + [f"ST-{str(i).zfill(2)}" for i in range(1, 31)]

# Directories
src_index = Path("assets/data/sets_index.json")
output_dir = Path("output")
output_index = output_dir / "sets_index.json"
dest_dir = Path("assets/data")

# Create output dir if not exists
output_dir.mkdir(parents=True, exist_ok=True)

# 1. Copy assets/data/sets_index.json to output/sets_index.json so we preserve existing sets (OP, EB, PRB-01)
if src_index.exists():
    print(f"📋 Copying {src_index} to {output_index} to preserve other sets...")
    shutil.copy(src_index, output_index)
else:
    print("⚠️ No existing sets_index.json found in assets/data!")

# 2. Sequential scrape loop
total = len(targets)
for idx, set_code in enumerate(targets):
    print(f"\n==================================================")
    print(f"🚀 [{idx+1}/{total}] SCRAPING SET: {set_code}")
    print(f"==================================================")
    
    # Run the scraper script
    # We use --delay 1.5 to be respectful to Bandai's servers and avoid rate limits/blocks
    cmd = [sys.executable, "onepiece_scraper.py", "--set", set_code, "--delay", "1.5"]
    print(f"Running command: {' '.join(cmd)}")
    
    res = subprocess.run(cmd)
    
    if res.returncode == 0:
        print(f"✅ Scraped {set_code} successfully!")
        
        # 3. Copy scraped set directory to assets/data
        src_set_dir = output_dir / set_code
        dest_set_dir = dest_dir / set_code
        
        if src_set_dir.exists():
            if dest_set_dir.exists():
                shutil.rmtree(dest_set_dir)
            shutil.copytree(src_set_dir, dest_set_dir)
            print(f"💾 Copied data to {dest_set_dir}")
        else:
            print(f"⚠️ Warning: Scraped set directory {src_set_dir} not found!")
            
        # 4. Copy updated sets_index.json back to assets/data/sets_index.json
        if output_index.exists():
            shutil.copy(output_index, src_index)
            print(f"💾 Updated {src_index} with {set_code} metadata.")
    else:
        print(f"❌ Failed to scrape {set_code} (Exit code: {res.returncode})")

print("\n==================================================")
print("🎉 Batch Scraping & Integration Complete!")
print("==================================================")
