import os
import subprocess
import time

UDID = "52415E8D-5DC0-421F-A5B2-F08E6BE11468"
ROOT = "/Users/vietnguyen/DATA/PRIVATE/hyper_render_offlical"
ASSETS = os.path.join(ROOT, "assets")
TMP = os.path.join(ROOT, ".demo_recordings")
os.makedirs(TMP, exist_ok=True)
os.makedirs(ASSETS, exist_ok=True)

DEMOS = [
    ("float", "float_demo"),
    ("ruby", "ruby_demo"),
    ("selection", "selection_demo"),
    ("table", "table_demo"),
    ("comparison", "comparison_demo"),
    ("performance", "performance_demo"),
]

for demo_id, output_name in DEMOS:
    print(f"🎬 Recording: {demo_id} -> {output_name}.gif")
    mp4_path = os.path.join(TMP, f"{output_name}.mp4")
    gif_path = os.path.join(ASSETS, f"{output_name}.gif")
    palette_path = os.path.join(TMP, f"palette_{output_name}.png")

    # Set active demo
    with open('/tmp/active_demo.txt', 'w') as f:
        f.write(demo_id)

    # Terminate and launch installed app directly
    subprocess.run(["xcrun", "simctl", "terminate", UDID, "io.brewkits.hyper-render.example"], check=False)
    time.sleep(0.5)
    subprocess.run(["xcrun", "simctl", "launch", UDID, "io.brewkits.hyper-render.example"], check=True)

    # Wait for UI to render and animation/scroll to run
    print("⏳ Waiting for UI render...")
    time.sleep(1.5)

    # Record 4 seconds of active animation
    print(f"🎥 Recording video to {mp4_path}...")
    rec_proc = subprocess.Popen(["xcrun", "simctl", "io", UDID, "recordVideo", "-f", "--codec=h264", mp4_path])
    time.sleep(4.5)
    rec_proc.send_signal(subprocess.signal.SIGINT)
    rec_proc.wait()

    # Terminate simulator app process
    subprocess.run(["xcrun", "simctl", "terminate", UDID, "io.brewkits.hyper-render.example"], check=False)
    time.sleep(0.5)

    # Convert to high quality GIF
    print("🎨 Converting with ffmpeg...")
    subprocess.run([
        "ffmpeg", "-y", "-i", mp4_path,
        "-vf", "scale=360:-1:flags=lanczos,fps=16,palettegen=max_colors=192",
        "-update", "1", palette_path,
        "-loglevel", "error"
    ], check=True)

    subprocess.run([
        "ffmpeg", "-y", "-i", mp4_path, "-i", palette_path,
        "-filter_complex", "scale=360:-1:flags=lanczos,fps=16[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle",
        "-loop", "0", gif_path,
        "-loglevel", "error"
    ], check=True)

    size = os.path.getsize(gif_path) / (1024 * 1024)
    print(f"✅ Generated {output_name}.gif ({size:.2f} MB)")
    print("-" * 50)

print("🎉 ALL 6 DEMO GIFS SUCCESSFULLY RECORDED AND CONVERTED!")
