#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt
import os

# ================= CONFIG =================
CSV_FILE = "data/MT25190_PART_D_CSV.csv"
PLOTS_DIR = "plots_part_d"

METRICS = {
    "CPU%": "CPU Utilization (%)",
    "Mem(KB)": "Memory Usage (KB)",
    "Time(s)": "Execution Time (s)",
    "context_switches_per_sec": "Context Switches / sec",
    "page_faults_total": "Total Page Faults"
}

WORKER_TYPES = ["cpu", "mem", "io"]
PROGRAMS = {
    "program_a": "Program A (Processes)",
    "program_b": "Program B (Threads)"
}

LINE_STYLES = {
    "cpu": "-o",
    "mem": "--s",
    "io": ":^"
}

# ================= LOAD DATA =================
df = pd.read_csv(CSV_FILE)

os.makedirs(PLOTS_DIR, exist_ok=True)

# ================= PLOTTING =================
for metric, ylabel in METRICS.items():
    fig, axes = plt.subplots(1, 2, figsize=(14, 6), sharey=True)

    for idx, (prog_key, prog_label) in enumerate(PROGRAMS.items()):
        ax = axes[idx]
        df_prog = df[df["Program"] == prog_key]

        for wtype in WORKER_TYPES:
            df_w = df_prog[df_prog["WorkerType"] == wtype].sort_values("NumWorkers")

            ax.plot(
                df_w["NumWorkers"],
                df_w[metric],
                LINE_STYLES[wtype],
                label=wtype.upper(),
                linewidth=2,
                markersize=7
            )

        ax.set_title(prog_label, fontsize=13, fontweight="bold")
        ax.set_xlabel("Number of Workers", fontsize=11)
        ax.grid(True, alpha=0.3)

        if idx == 0:
            ax.set_ylabel(ylabel, fontsize=11)

        ax.legend()

    plt.suptitle(f"{ylabel} vs Number of Workers", fontsize=15, fontweight="bold")
    plt.tight_layout(rect=[0, 0, 1, 0.95])

    out_file = os.path.join(PLOTS_DIR, f"{metric}_vs_NumWorkers.png")
    plt.savefig(out_file, dpi=300)
    plt.close()

    print(f"Saved: {out_file}")

print("\nAll Part D plots generated successfully.")
