#!/usr/bin/python3

import tkinter as tk
from tkinter import ttk
import time
import os
from subprocess import run, PIPE
from csv import writer
from dataclasses import dataclass, field
from typing import Optional, Any
from stressmon.cpuinfo import CPUInfo
from stressmon.cpuusage import CPUUsage
from stressmon.cpuwatts import CPUWatts
from stressmon.cputemp import CPUTemp
from stressmon.cpufreq import CPUFreq
from stressmon.memusage import MemUsage
from stressmon.drivetemp import DriveTemp
from stressmon.gpudata import GPUData
from stressmon.sysfan import SysFan
from stressmon.updatepool import UpdatePool

@dataclass
class OutputData:
    """Data for output updatepool functions"""
    csv_fn: Optional[str] = field(default=None)
    summary_fn: Optional[str] = field(default=None)
    run_time: Optional[float] = field(default=None)
    iterations: Optional[int] = field(default=None)
    watts: Optional[CPUWatts] = field(default=None)
    mhz: Optional[CPUFreq] = field(default=None)
    ctemps: Optional[CPUTemp] = field(default=None)
    fans: Optional[SysFan] = field(default=None)
    gpus: Optional[GPUData] = field(default=None)
    drives: Optional[DriveTemp] = field(default=None)
    usage: Optional[CPUUsage] = field(default=None)
    mem: Optional[MemUsage] = field(default=None)
    data: Optional[list] = field(default=None)
    time: Optional[str] = field(default=None)
    model_name: Optional[str] = field(default=None)

def get_model_name() -> str:
    """Get the system's model name"""
    return run(["sudo dmidecode -t 1 | grep Version | awk '{print $2}'"],
               shell=True,
               check=True,
               stdout=PIPE).stdout.decode('utf-8').strip()

def write_csv(output_data: OutputData) -> None:
    """Append current data to log csv file"""
    with open(file=output_data.csv_fn, mode='a', encoding='utf-8') as outfile:
        csv_writer = writer(outfile)
        csv_writer.writerow(output_data.data)
        
def center_colon(usage, freq, width=15):
    """Center the colon between usage and frequency values."""
    usage_str = f"{usage}%"
    freq_str = f"{freq} MHz"
    total_length = len(usage_str) + len(freq_str) + 3  # including spaces around colon
    padding = max(width - total_length, 0) // 2
    return f"{usage_str}{' ' * padding}:{' ' * padding}{freq_str}"

def format_line(items, column_widths, justifications):
    """
    Formats a single line (header or data) with specified column widths and justifications.
    """
    line_format = "".join(["{:" + just + str(width) + "}" for just, width in zip(justifications, column_widths)]) + "\n"
    return line_format.format(*items)

def write_summary(output_data: OutputData) -> None:
    """Output current state to summary log file"""
    mhz = output_data.mhz
    ctemps = output_data.ctemps
    watts = output_data.watts
    fans = output_data.fans
    gpus = output_data.gpus
    drives = output_data.drives
    usage = output_data.usage
    mem = output_data.mem
    model_name = output_data.model_name

    data = f"Summary:\nModel: {model_name}\nStart Time: {output_data.time}\n"
    data += f"Runtime: {output_data.run_time}\nCPU: {mhz.get_model()}\n"
    data += "Memory SKUs:\n"
    for sku in mem.get_mem_skus():
        data += f"DIMM: {sku}\n"
    mem_type = ''
    column_widths = [15, 20, 20, 20]
    justifications = ['<', '>', '>', '>']
    headers = []
    for params in mem:
        if mem_type != params[0]:
            mem_type = params[0]
            headers = [mem_type, "Min", "Max", "Mean"]
            data += format_line(headers, column_widths, justifications)
        data_row = [mem.get_label(params), mem.get_min(params),
                    mem.get_max(params), mem.get_mean(params)]
        data += format_line(data_row, column_widths, justifications)
    column_widths = [15, 15, 15, 15]
    justifications = ['<', '>', '>', '>']
    headers = ["Core", "Min %:Mhz", "Max %:Mhz", "Mean %:Mhz"]
    data += format_line(headers, column_widths, justifications)
    for mhz_params, usage_params in zip(mhz, usage):
        data_row = [mhz.get_label(mhz_params), 
                    f"{usage.get_min(usage_params):>4}:{mhz.get_min(mhz_params):>5}",
                    f"{usage.get_max(usage_params):>4}:{mhz.get_max(mhz_params):>5}",
                    f"{usage.get_mean(usage_params):>4}:{mhz.get_mean(mhz_params):>5}"]
        data += format_line(data_row, column_widths, justifications)
    data += "\n"
    if not ctemps.is_empty():
        column_widths = [15, 10, 10, 10]
        justifications = ['<', '>', '>', '>']
        headers = ["Core", "Min C", "Max C", "Mean C"]
        data += format_line(headers, column_widths, justifications)
        for params in ctemps:
            data_row = [ctemps.get_label(params), ctemps.get_min(params),
                        ctemps.get_max(params), ctemps.get_mean(params)]
            data += format_line(data_row, column_widths, justifications)
        data += "\n"
    if not watts.is_empty():
        column_widths = [10, 10, 10, 10]
        justifications = ['<', '>', '>', '>']
        headers = ["CPU", "Min W", "Max W", "Mean W"]
        data += format_line(headers, column_widths, justifications)
        for params in watts:
            data_row = [watts.get_label(params), watts.get_min(params),
                        watts.get_max(params), watts.get_mean(params)]
            data += format_line(data_row, column_widths, justifications)
        data += "\n"
    if not fans.is_empty():
        data += "Fans\n"
        driver = ''
        column_widths = [15, 15, 15, 15, 15]
        justifications = ['<', '>', '>', '>', '>']
        for params in fans:
            if driver != params[0]:
                driver = params[0]
                data += f"{driver}:\n"
                headers = ["Fan", "Current(RPM)", "Min(RPM)", "Max(RPM)", "Mean(RPM)"]
                data += format_line(headers, column_widths, justifications)
            data_row = [fans.get_label(params), fans.get_current(params), fans.get_min(params),
                        fans.get_max(params), fans.get_mean(params)]
            data += format_line(data_row, column_widths, justifications)
        data += "\n"
    if not gpus.is_empty():
        data += "GPUs\n"
        vendor = ''
        name = ''
        column_widths = [15, 15, 15, 15, 15]
        justifications = ['<', '>', '>', '>', '>']
        for params in gpus:
            driver_version = ""
            if vendor != params[0]:
                vendor = params[0]
                if vendor == 'nvidia':
                    driver_version = " - " + gpus.get_driver_version()
                data += f"{vendor}{driver_version}:\n"
            if name != params[1]:
                name = params[1]
                data += f"GPU: {name}\n"
                if gpus.get_subven(vendor, name):
                    data += f"SubSystem: {gpus.get_subven(vendor, name)}\n"
                headers = ["Data", "Current", "Min", "Max", "Mean"]
                data += format_line(headers, column_widths, justifications)
            if gpus.get_current(params) is not None:
                data_row = [gpus.get_label(params), gpus.get_current(params), gpus.get_min(params),
                            gpus.get_max(params), gpus.get_mean(params)]
                data += format_line(data_row, column_widths, justifications)
        data += "\n"
    if not drives.is_empty():
        data += "Drives\n"
        drive = ''
        column_widths = [15, 15, 15, 15, 15]
        justifications = ['<', '>', '>', '>', '>']
        headers = ["Data", "Current", "Min", "Max", "Mean"]
        for params in drives:
            if drive != params[0]:
                drive = params[0]
                data += f"Device: {drive}\nDrive Model: {drives.get_model(drive)}\n"
                data += format_line(headers, column_widths, justifications)
            if drives.get_current(params) is not None:
                data_row = [drives.get_label(params), drives.get_current(params),
                            drives.get_min(params), drives.get_max(params),
                            drives.get_mean(params)]
                data += format_line(data_row, column_widths, justifications)
        data += "\n"
    with open(file=output_data.summary_fn, mode='w', encoding='utf-8') as outfile:
        outfile.write(data)

class RealTimeOutputGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("System76 Monitor")

        self.start_time = None

        # Initialize stressmon classes
        self.cpu_info = CPUInfo()
        self.cpu_usage = CPUUsage()
        self.cpu_watts = CPUWatts()
        self.cpu_temp = CPUTemp()
        self.cpu_freq = CPUFreq()
        self.mem_usage = MemUsage()
        self.drive_temp = DriveTemp()
        self.gpu_data = GPUData()
        self.sys_fan = SysFan()

        # Initialize UpdatePool
        self.update_pool = UpdatePool()
        self.update_pool.add_executor('cpu_usage', self.cpu_usage.update)
        self.update_pool.add_executor('cpu_watts', self.cpu_watts.update)
        self.update_pool.add_executor('cpu_temp', self.cpu_temp.update)
        self.update_pool.add_executor('cpu_freq', self.cpu_freq.update)
        self.update_pool.add_executor('mem_usage', self.mem_usage.update)
        self.update_pool.add_executor('drive_temp', self.drive_temp.update)
        self.update_pool.add_executor('gpu_data', self.gpu_data.update)
        self.update_pool.add_executor('sys_fan', self.sys_fan.update)

        # Prepare logging
        log_dir = os.path.join(os.getcwd(), "logs")
        os.makedirs(log_dir, exist_ok=True)
        save_time = time.strftime("%Y-%m-%d-%H_%M_%S")
        self.csv_file = os.path.join(log_dir, f"log_{save_time}.csv")
        self.summary_file = os.path.join(log_dir, f"log_{save_time}.txt")
        
        self.cpu_model = self.cpu_info.get_model()
        
        self.gpu_units = {'temp': ' °C',
                          'clock': ' MHz',
                          'fan_speed': {'amdgpu': ' RPM', 'nvidia': '%'},
                          'power': ' W',
                          'memory': ' MB',
                          'utilization': '%'
                         }

        vendors = self.gpu_data.get_vendors()
        self.gpu_names = []
        for vendor in vendors:
            self.gpu_names = self.gpu_names + self.gpu_data.get_gpu_names(vendor)
            
        headings = ["Runtime"] + self.cpu_freq.get_csv_headings() + \
                   self.cpu_temp.get_csv_headings() + \
                   self.cpu_watts.get_csv_headings() + \
                   self.sys_fan.get_csv_headings() + \
                   self.gpu_data.get_csv_headings() + \
                   self.drive_temp.get_csv_headings() + \
                   self.mem_usage.get_csv_headings() + \
                   self.cpu_usage.get_csv_headings()

        self.output_data = OutputData()
        self.output_data.csv_fn = self.csv_file
        self.output_data.summary_fn = self.summary_file
        self.output_data.data = headings
        self.output_data.iterations = 0
        self.output_data.mhz = self.cpu_freq
        self.output_data.ctemps = self.cpu_temp
        self.output_data.watts = self.cpu_watts
        self.output_data.fans = self.sys_fan
        self.output_data.gpus = self.gpu_data
        self.output_data.drives = self.drive_temp
        self.output_data.usage = self.cpu_usage
        self.output_data.mem = self.mem_usage
        self.output_data.model_name = get_model_name()
        self.output_data.time = time.strftime("%Y-%m-%d %H:%M:%S")

        self.gpu_model_labels = []
        self.cpu_watts_labels = []
        self.memory_labels = []
        self.drive_labels = []
        self.drive_trees = []
        self.gpu_labels = []
        self.gpu_trees = []
        self.fan_labels = []
        self.fan_trees = []

        # Perform initial update to populate data
        self.update_pool.do_updates()

        self.create_widgets()
        self.update_data()

    def create_widgets(self):
        # Header section
        rows = 0
        
        self.header_frame = tk.Frame(self.root)
        self.header_frame.pack(fill='x', padx=10, pady=5)

        self.system_info_label = tk.Label(self.header_frame, text="", font=("Arial", 12))
        self.system_info_label.grid(row=rows, column=0, sticky='w', padx=3, pady=3)
        
        rows += 1
        
        for i in range(len(self.gpu_names)):
            label = tk.Label(self.header_frame, text="", font=("Arial", 12))
            label.grid(row=i + rows, column=0, sticky='w', padx=3, pady=3)
            self.gpu_model_labels.append(label)
            rows += 1

        self.runtime_label = tk.Label(self.header_frame, text="", font=("Arial", 12))
        self.runtime_label.grid(row=rows, column=0, sticky='w', padx=3, pady=3)
        
        rows += 1
        
        self.iteration_label = tk.Label(self.header_frame, text="", font=("Arial", 12))
        self.iteration_label.grid(row=rows, column=0, sticky='w', padx=3, pady=3)
        
        rows += 1

        # Initialize the CPU watts labels with empty text
        for i in range(self.cpu_watts.get_count()):
            label = tk.Label(self.header_frame, text="", font=("Arial", 12))
            label.grid(row=i + rows, column=0, sticky='w', padx=3, pady=3)
            self.cpu_watts_labels.append(label)

        # Initialize the Memory labels with empty text
        for i in range(2):  # For 'Mem' and 'Swap'
            label = tk.Label(self.header_frame, text="", font=("Arial", 12))
            label.grid(row=rows + self.cpu_watts.get_count() + i, column=0, sticky='w', padx=3, pady=3)
            self.memory_labels.append(label)

        # Create a notebook (tabbed interface)
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(expand=True, fill='both')

        # Create CPU frame and tab
        self.cpu_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.cpu_tab, text='CPU')
        self.cpu_tree_label = tk.Label(self.cpu_tab, text="CPU Utilization : Frequency", font=("Arial", 12, "bold"))
        self.cpu_tree_label.pack(fill='x', padx=5, pady=5)
        self.cpu_tree = self.create_treeview(self.cpu_tab, ["Label", "Current", "Min", "Max", "Mean"])
        self.cpu_temp_tree_label = tk.Label(self.cpu_tab, text="CPU Temperatures", font=("Arial", 12, "bold"))
        self.cpu_temp_tree_label.pack(fill='x', padx=5, pady=5)
        self.cpu_temp_tree = self.create_treeview(self.cpu_tab, ["Label", "Current", "Min", "Max", "Mean"])
        
        # Create GPU frame and tab if a GPU is present
        if not self.gpu_data.is_empty():
            self.gpu_tab = ttk.Frame(self.notebook)
            self.notebook.add(self.gpu_tab, text='GPU')
            for gpu_name in self.gpu_names:
                label = tk.Label(self.gpu_tab, text=gpu_name, font=("Arial", 12, "bold"))
                label.pack(fill='x', padx=5, pady=5)
                tree = self.create_treeview(self.gpu_tab, ["Label", "Current", "Min", "Max", "Mean"])
                self.gpu_labels.append(label)
                self.gpu_trees.append(tree)
        
        # create disk frame and tab if disk is present
        if not self.drive_temp.is_empty():
            self.disk_tab = ttk.Frame(self.notebook)
            self.notebook.add(self.disk_tab, text='Disk')
            for drive_name in self.drive_temp.get_drive_names():
                label = tk.Label(self.disk_tab, text=drive_name, font=("Arial", 12, "bold"))
                label.pack(fill='x', padx=5, pady=5)
                tree = self.create_treeview(self.disk_tab, ["Label", "Current", "Min", "Max", "Mean"])
                self.drive_labels.append(label)
                self.drive_trees.append(tree)
            
        # create fans frame and tab if fan is present
        if not self.sys_fan.is_empty():
            self.fan_tab = ttk.Frame(self.notebook)
            self.notebook.add(self.fan_tab, text='Fan')
            for fan_driver in self.sys_fan.get_drivers():
                label = tk.Label(self.fan_tab, text=fan_driver, font=("Arial", 12, "bold"))
                label.pack(fill='x', padx=5, pady=5)
                tree = self.create_treeview(self.fan_tab, ["Label", "Current", "Min", "Max", "Mean"])
                self.fan_labels.append(label)
                self.fan_trees.append(tree)

    def create_treeview(self, parent, columns):
        tree = ttk.Treeview(parent, columns=columns, show="headings")
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, minwidth=0, width=150)
        tree.pack(expand=True, fill='both')
        return tree

    def update_treeview(self, tree, data):
        for item in tree.get_children():
            tree.delete(item)
        for row in data:
            tree.insert("", "end", values=row)

    def update_cpu_watts_labels(self):
        for i, params in enumerate(self.cpu_watts):
            label_text = f"{self.cpu_watts.get_label(params)}: {self.cpu_watts.get_current(params):>4}W (Min: {self.cpu_watts.get_min(params):>4}W, Max: {self.cpu_watts.get_max(params):>4}W, Mean: {self.cpu_watts.get_mean(params):>4}W)"
            self.cpu_watts_labels[i].config(text=label_text)
            
    def update_memory_labels(self):
        mem_type = ''
        mem_total = 0
        mem_used = 0
        index = 0
        
        for params in self.mem_usage:
            if params[0] != mem_type:
                mem_type = params[0]
            if params[1] == 'Used':
                mem_used = self.mem_usage.get_current(params)
            if params[1] == 'Total':
                mem_total = self.mem_usage.get_current(params)
            if params[1] == 'Percent':
                label_text = f"{mem_type}: {mem_used:>{15},} / {mem_total:>{15},} [{self.mem_usage.get_current(params):>3}%]"
                self.memory_labels[index].config(text=label_text)
                index += 1

    def update_data(self):
        # Perform asynchronous updates using the update pool
        self.update_pool.do_updates()

        # Get data from stressmon methods
        system_info = f"System Info: {self.output_data.model_name}\tCPU: {self.cpu_model}"
        if not self.start_time:
            self.start_time = round(time.time_ns() / 1000000)
        self.output_data.runtime = self.output_data.run_time = (round(time.time_ns() / 1000000) - self.start_time) / 1000
        self.output_data.iterations += 1

        # Get CPU data
        cpu_data = []
        for usage_params, freq_params in zip(self.cpu_usage, self.cpu_freq):
            label = self.cpu_usage.get_label(usage_params)
            current = center_colon(self.cpu_usage.get_current(usage_params), self.cpu_freq.get_current(freq_params))
            min_val = center_colon(self.cpu_usage.get_min(usage_params), self.cpu_freq.get_min(freq_params))
            max_val = center_colon(self.cpu_usage.get_max(usage_params), self.cpu_freq.get_max(freq_params))
            mean_val = center_colon(self.cpu_usage.get_mean(usage_params), self.cpu_freq.get_mean(freq_params))
            cpu_data.append([label, current, min_val, max_val, mean_val])

        cpu_temp_data = []
        for params in self.cpu_temp:
            label = self.cpu_temp.get_label(params)
            current = f"{self.cpu_temp.get_current(params):>4} °C"
            min_val = f"{self.cpu_temp.get_min(params):>4} °C"
            max_val = f"{self.cpu_temp.get_max(params):>4} °C"
            mean_val = f"{self.cpu_temp.get_mean(params):>4} °C"
            cpu_temp_data.append([label, current, min_val, max_val, mean_val])

        # Get GPU data
        if not self.gpu_data.is_empty():
            gpu_data = {gpu_name: [] for gpu_name in self.gpu_names}
            vendor = ''
            name = ''
            for params in self.gpu_data:
                if vendor != self.gpu_data.get_section(params):
                    vendor = self.gpu_data.get_section(params)
                if name != self.gpu_data.get_subsection(params):
                    name = self.gpu_data.get_subsection(params)
                label = self.gpu_data.get_label(params)
                if label == "fan_speed":
                    unit = f"{self.gpu_units[label][vendor]}"
                else:
                    unit = f"{self.gpu_units[label]}"
                raw_current = self.gpu_data.get_current(params)
                current = f"{raw_current}{unit}"
                min_val = f"{self.gpu_data.get_min(params)}{unit}"
                max_val = f"{self.gpu_data.get_max(params)}{unit}"
                mean_val = f"{self.gpu_data.get_mean(params)}{unit}"
                if raw_current is not None:
                    gpu_data[name].append([label, current, min_val, max_val, mean_val])

        # Get disk data
        if not self.drive_temp.is_empty():
            drive_data = {drive_name: [] for drive_name in self.drive_temp.get_drive_names()}
            drive = ''
            models = []
            name = ''
            for params in self.drive_temp:
                if drive != self.drive_temp.get_section(params):
                    drive = self.drive_temp.get_section(params)
                    models.append(drive)
                    name = params[0]
                label = self.drive_temp.get_label(params)
                current = f"{self.drive_temp.get_current(params)} °C"
                min_val = f"{self.drive_temp.get_min(params)} °C"
                max_val = f"{self.drive_temp.get_max(params)} °C"
                mean_val = f"{self.drive_temp.get_mean(params)} °C"
                drive_data[name].append([label, current, min_val, max_val, mean_val])

        # Get fan data
        if not self.sys_fan.is_empty():
            fan_data = {fan_driver: [] for fan_driver in self.sys_fan.get_drivers()}
            driver = ''
            for params in self.sys_fan:
                if driver != self.sys_fan.get_section(params):
                    driver = self.sys_fan.get_section(params)
                label = self.sys_fan.get_label(params)
                current = f"{self.sys_fan.get_current(params)} RPM"
                min_val = f"{self.sys_fan.get_min(params)} RPM"
                max_val = f"{self.sys_fan.get_max(params)} RPM"
                mean_val = f"{self.sys_fan.get_mean(params)} RPM"
                fan_data[driver].append([label, current, min_val, max_val, mean_val])

        self.system_info_label.config(text=system_info)
        self.runtime_label.config(text=f"Run Time: {self.output_data.runtime}")
        self.iteration_label.config(text=f"Iterations: {self.output_data.iterations}")
        
        if not self.gpu_data.is_empty():
            for i in range(len(self.gpu_names)):
                self.gpu_model_labels[i].config(text=f"GPU{i}: {self.gpu_names[i]}")

        # Update CPU watts labels
        self.update_cpu_watts_labels()

        # Update Memory labels
        self.update_memory_labels()

        # Update Treeview widgets with the data
        self.update_treeview(self.cpu_tree, cpu_data)
        self.update_treeview(self.cpu_temp_tree, cpu_temp_data)
        if not self.drive_temp.is_empty():
            for i, drive_name in enumerate(self.drive_temp.get_drive_names()):
                self.drive_labels[i].config(text=models[i])
                self.update_treeview(self.drive_trees[i], drive_data[drive_name])
        if not self.gpu_data.is_empty():
            for i, gpu_name in enumerate(self.gpu_names):
                self.update_treeview(self.gpu_trees[i], gpu_data[gpu_name])
        if not self.sys_fan.is_empty():
            for i, fan_driver in enumerate(self.sys_fan.get_drivers()):
                self.update_treeview(self.fan_trees[i], fan_data[fan_driver])

        # Update log data
        self.output_data.data = [self.output_data.run_time] + \
                                self.output_data.mhz.get_csv_data() + \
                                self.output_data.ctemps.get_csv_data() + \
                                self.output_data.watts.get_csv_data() + \
                                self.output_data.fans.get_csv_data() + \
                                self.output_data.gpus.get_csv_data() + \
                                self.output_data.drives.get_csv_data() + \
                                self.output_data.mem.get_csv_data() + \
                                self.output_data.usage.get_csv_data()

        # Write to CSV and summary logs
        write_csv(self.output_data)
        write_summary(self.output_data)

        # Schedule the update_data method to be called after 1 second
        self.root.after(66, self.update_data)

if __name__ == "__main__":
    root = tk.Tk()
    gui = RealTimeOutputGUI(root)
    root.mainloop()

