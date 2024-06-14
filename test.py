#!/usr/bin/python3
"""Monitor and record CPU clock speeds and temps
"""

from argparse import ArgumentParser
from dataclasses import dataclass, field
from typing import Optional, Any
from os import getlogin
from time import sleep, time_ns
from subprocess import run, PIPE
from curses import wrapper
from datetime import datetime
from csv import writer
from stressmon import CPUFreq, CPUTemp, DriveTemp, SysFan, GPUData, CPUWatts, CPUUsage, MemUsage
from stressmon import UpdatePool

@dataclass
class OutputPoolData:
    """Data for output updatepool functions
    """
    window: Any = field(default=None)
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
    """Get the system's model name
    """
    return run(["sudo dmidecode -t 1 | grep Version | awk '{print $2}'"],
               shell=True,
               check=True,
               stdout=PIPE).stdout.decode('utf-8').strip()

def main(window: any) -> None:
    """main program entrypoint.
    """

    parser = ArgumentParser(description="Script description")
    parser.add_argument("-s", "--serialnum", help="System serial number")
    args = parser.parse_args()

    local_user = getlogin()

    save_time: str = datetime.now().strftime("%Y-%m-%d-%H_%M_%S")
    fn_time: str = datetime.now().strftime("%m-%d-%Y %H:%M:%S")
    file_name: str = f"log_{save_time}.csv"
    summary_file_name: str = f"log_{save_time}.txt"
    if args.serialnum:
        file_name = f"/home/{local_user}/Desktop/burn-in_log_{args.serialnum}.csv"
        summary_file_name = f"/home/{local_user}/Desktop/burn-in_log_{args.serialnum}.txt"
    mhz: CPUFreq = CPUFreq()
    ctemps: CPUTemp = CPUTemp()
    watts: CPUWatts = CPUWatts()
    fans: SysFan = SysFan()
    gpus: GPUData = GPUData()
    drives: DriveTemp = DriveTemp()
    usage: CPUUsage = CPUUsage()
    mem: MemUsage = MemUsage()
    sensors: UpdatePool = UpdatePool()
    output: UpdatePool = UpdatePool()
    sensors.add_executor('mhz', mhz.update)
    sensors.add_executor('ctemps', ctemps.update)
    sensors.add_executor('watts', watts.update)
    sensors.add_executor('fans', fans.update)
    sensors.add_executor('gpus', gpus.update)
    sensors.add_executor('drives', drives.update)
    sensors.add_executor('usage', usage.update)
    sensors.add_executor('mem', mem.update)
    sensors.do_updates()
    output.add_executor('display', update_display)
    output.add_executor('csv_writer', write_csv)
    output.add_executor('summary_writer', write_summary)
    headings: list = ["Runtime"] + mhz.get_csv_headings() + ctemps.get_csv_headings() + \
                     watts.get_csv_headings() + fans.get_csv_headings() + \
                     gpus.get_csv_headings() + drives.get_csv_headings() + \
                     mem.get_csv_headings() + usage.get_csv_headings()
    window.resize(len(mhz.get_csv_data()) + 25, 175)
    output_data: OutputPoolData = OutputPoolData()
    output_data.window = window
    output_data.csv_fn = file_name
    output_data.summary_fn = summary_file_name
    output_data.mhz = mhz
    output_data.ctemps = ctemps
    output_data.watts = watts
    output_data.fans = fans
    output_data.gpus = gpus
    output_data.drives = drives
    output_data.usage = usage
    output_data.mem = mem
    output_data.iterations = 1
    output_data.data = headings
    output_data.time = fn_time
    output_data.model_name = get_model_name()
    write_csv(output_data)
    start_time: int = round(time_ns() / 1000000)
    while True:
        loop_start: int = time_ns()
        output_data.run_time = (round(time_ns() / 1000000) - start_time) / 1000
        output_data.data = [output_data.run_time] + mhz.get_csv_data() + ctemps.get_csv_data() + \
                           watts.get_csv_data() + fans.get_csv_data() + gpus.get_csv_data() + \
                           drives.get_csv_data() + mem.get_csv_data() + usage.get_csv_data()
        output.do_updates(output_data)
        output_data.iterations += 1
        sensors.do_updates()
        loop_duration: int = time_ns() - loop_start
        sleep_time: float = (100000000 - loop_duration) / 1000000000
        if sleep_time < 0:
            sleep_time = 0
        sleep(sleep_time)

def update_display(output_data: OutputPoolData):
    """Update data displayed
    """
    window = output_data.window
    mhz = output_data.mhz
    watts = output_data.watts
    ctemps = output_data.ctemps
    fans = output_data.fans
    gpus = output_data.gpus
    drives = output_data.drives
    usage = output_data.usage
    mem = output_data.mem
    index: int = 0
    window.resize(len(mhz.get_csv_data()) + 25, 175)
    time: str = datetime.now().strftime("%m-%d-%Y %H:%M:%S")
    window.addstr(index, 0, f"Time: {time}\tRuntime: {output_data.run_time}")
    window.clrtobot()
    window.addstr(index, 65, f"Iterations: {output_data.iterations}")
    index += 1
    window.addstr(index, 0, f"Model: {output_data.model_name}")
    index += 1
    window.addstr(index, 0, watts.get_section([]))
    index += 1
    window.addstr(index, 0, "CPU")
    window.addstr(index, 10, "Current(W)")
    window.addstr(index, 24, "Min(W)")
    window.addstr(index, 34, "Max(W)")
    window.addstr(index, 44, "Mean(W)")
    for params in watts:
        index += 1
        window.addstr(index, 0, f"{watts.get_label(params)}")
        window.addstr(index, 10, f"{watts.get_current(params):>4}\t")
        window.addstr(index, 24, f"{watts.get_min(params):>4}\t")
        window.addstr(index, 34, f"{watts.get_max(params):>4}\t")
        window.addstr(index, 44, f"{watts.get_mean(params):>4}\t")
    index += 1
    window.addstr(index, 0, "Memory:")
    index += 1
    mem_type: str = ''
    mem_total = 0
    mem_used = 0
    for params in mem:
        if params[0] != mem_type:
            mem_type = params[0]
        if params[1] == 'Used':
            mem_used = mem.get_current(params)
        if params[1] == 'Total':
            mem_total = mem.get_current(params)
        if params[1] == 'Percent':
            window.addstr(index, 0, f"{mem_type}: ")
            window.addstr(index, 8, f"{mem_used:>{15},}")
            window.addstr(index, 25, "/")
            window.addstr(index, 28, f"{mem_total:>{15},}")
            window.addstr(index, 48, f"[{mem.get_current(params):>3}%]")
            index += 1
    window.addstr(index, 0, mhz.get_section([]))
    window.addstr(index, 70, ctemps.get_section([]))
    index += 1
    window.addstr(index, 0, "Core")
    window.addstr(index, 10, "Current(%:MHz)")
    window.addstr(index, 26, "Min(%:MHz)")
    window.addstr(index, 38, "Max(%:MHz)")
    window.addstr(index, 50, "Mean(%:MHz)")
    window.addstr(index, 70, "Core")
    window.addstr(index, 85, "Current(C)")
    window.addstr(index, 100, "Min(C)")
    window.addstr(index, 110, "Max(C)")
    window.addstr(index, 120, "Mean(C)")
    temp_index = index
    for mhz_params, usage_params in zip(mhz, usage):
        index += 1
        window.addstr(index, 0, f"{mhz.get_label(mhz_params)}")
        window.addstr(index, 14,
                      f"{usage.get_current(usage_params):>4}:{mhz.get_current(mhz_params):>5}\t")
        window.addstr(index, 26,
                      f"{usage.get_min(usage_params):>4}:{mhz.get_min(mhz_params):>5}\t")
        window.addstr(index, 38,
                      f"{usage.get_max(usage_params):>4}:{mhz.get_max(mhz_params):>5}\t")
        window.addstr(index, 51,
                      f"{usage.get_mean(usage_params):>4}:{mhz.get_mean(mhz_params):>5}\t")
    index = temp_index
    for params in ctemps:
        index += 1
        window.addstr(index, 70, f"{ctemps.get_label(params)}")
        window.addstr(index, 91, f"{ctemps.get_current(params):>4}\t")
        window.addstr(index, 102, f"{ctemps.get_min(params):>4}\t")
        window.addstr(index, 112, f"{ctemps.get_max(params):>4}\t")
        window.addstr(index, 123, f"{ctemps.get_mean(params):>4}\t")
    index += 2
    if not fans.is_empty():
        driver = ''
        for params in fans:
            if driver != fans.get_section(params):
                driver = fans.get_section(params)
                window.addstr(index, 70, f"{driver}\t")
                index += 1
                window.addstr(index, 70, "Fan")
                window.addstr(index, 85, "Current(RPM)")
                window.addstr(index, 100, "Min(RPM)")
                window.addstr(index, 110, "Max(RPM)")
                window.addstr(index, 120, "Mean(RPM)")
            index += 1
            window.addstr(index, 70, f"{fans.get_label(params)}\t")
            window.addstr(index, 92, f"{fans.get_current(params):>5}\t")
            window.addstr(index, 103, f"{fans.get_min(params):>5}\t")
            window.addstr(index, 113, f"{fans.get_max(params):>5}\t")
            window.addstr(index, 124, f"{fans.get_mean(params):>5}\t")
    index += 2
    if not gpus.is_empty():
        vendor = ''
        name = ''
        for params in gpus:
            if vendor != gpus.get_section(params):
                vendor = gpus.get_section(params)
                window.addstr(index, 70, f"{vendor}\t")
            if name != gpus.get_subsection(params):
                name = gpus.get_subsection(params)
                index += 1
                window.addstr(index, 70, f"{name}\t")
                index += 1
                window.addstr(index, 70, "Data")
                window.addstr(index, 86, "Current")
                window.addstr(index, 105, "Min")
                window.addstr(index, 115, "Max")
                window.addstr(index, 124, "Mean")
            if gpus.get_current(params) is not None:
                index += 1
                window.addstr(index, 70, f"{gpus.get_label(params)}\t")
                window.addstr(index, 85, f"{gpus.get_current(params):>{8},}  \t")
                window.addstr(index, 100, f"{gpus.get_min(params):>{8},}\t")
                window.addstr(index, 110, f"{gpus.get_max(params):>{8},}\t")
                window.addstr(index, 120, f"{gpus.get_mean(params):>{8},}\t")
    index += 1
    if not drives.is_empty():
        drive = ''
        for params in drives:
            if drive != drives.get_section(params):
                drive = drives.get_section(params)
                index += 1
                window.addstr(index, 70, f"{drive}")
                index += 1
                window.addstr(index, 70, "Data")
                window.addstr(index, 85, "Current")
                window.addstr(index, 101, "Min")
                window.addstr(index, 111, "Max")
                window.addstr(index, 120, "Mean")
            if drives.get_current(params) is not None:
                index += 1
                window.addstr(index, 70, f"{drives.get_label(params)}\t")
                window.addstr(index, 88, f"{drives.get_current(params):>4}\t")
                window.addstr(index, 100, f"{drives.get_min(params):>4}\t")
                window.addstr(index, 110, f"{drives.get_max(params):>4}\t")
                window.addstr(index, 120, f"{drives.get_mean(params):>4}\t")
        index += 2
    window.refresh()

def write_csv(output_data: OutputPoolData) -> None:
    """Append current data to log csv file
    """
    with open(file=output_data.csv_fn, mode='a', encoding='utf-8') as outfile:
        csv = writer(outfile)
        csv.writerow(output_data.data)

def format_line(items, column_widths, justifications):
    """
    Formats a single line (header or data) with specified column widths and justifications.

    :param items: List of strings in the line.
    :param column_widths: List of widths for each column.
    :param justifications: List of justification types for each column ('<' for left, '>' for right, '^' for center).
    :return: Formatted line as a string.
    """
    line_format = "".join(["{:" + just + str(width) + "}" for just, width in zip(justifications, column_widths)]) + "\n"
    return line_format.format(*items)

def write_summary(output_data: OutputPoolData) -> None:
    """Output current state to summary log file
    """
    mhz = output_data.mhz
    ctemps = output_data.ctemps
    watts = output_data.watts
    fans = output_data.fans
    gpus = output_data.gpus
    drives = output_data.drives
    usage = output_data.usage
    mem = output_data.mem
    model_name = output_data.model_name

    data: str = f"Summary:\nModel: {model_name}\nStart Time: {output_data.time}\n"
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


if __name__ == '__main__':
    try:
        wrapper(main)
    except (KeyboardInterrupt, SystemExit):
        exit()
