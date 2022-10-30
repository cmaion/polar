## Synopsis
A set of command line tools written in Ruby to interact with Polar watches and decode raw data files.

* `polar_ftp`: access the Polar file system through USB
  * list content on the Polar watch
  * download raw files
  * backup complete content
* `polar_physdata2txt`: convert raw polar user physical data to TXT format
* `polar_dailysummary2txt`: convert raw polar daily summary to TXT format
* `polar_dailytrainingload2txt`: convert raw polar daily training load to TXT format
* `polar_activitysamples2csv`: convert raw polar daily activity samples (activity, steps, metabolic equivalent, sport id and inactivity notifications) to CSV format
* `polar_training2sml`: convert raw polar training sessions data files to the Suuntu SML file format
* `polar_training2gpx`: convert raw polar training sessions data files to the Garmin GPX file format
* `polar_training2tcx`: convert raw polar training sessions data files to the Garmin TCX file format
* `polar_fitnesstest2txt`: displays content of fitness test result and exports to TXT file
* `polar_training2rrtxt`: extracts RR intervals from polar training sessions data files
* `polar_rrrecord2txt`: displays content of RR recording results and exports to TXT file
* `polar_sleepanalysis2txt`: displays content of sleep analysis daily report and exports to TXT file
* `polar_nightlyrecharge2txt`: displays content of Nightly Recharge daily report and exports to TXT file

Tested with:
* old generation:
  * Polar M200
  * Polar M430
  * Polar V800
  * might also work on other models (A360, M400, Loop...), but this is untested
  * tested on Linux (Ubuntu 16.10), macOS (Yosemite) and Windows (10).
* new generation:
  * Polar Loop 2
  * Polar Ignite
  * Polar Vantage M, M2, V and V2
  * tested on Linux


## Platform specific prerequisites
### Linux
Install the ruby language (>= 2.1) and dev tools (C compiler & co), if necessary.

To be able to connect to the watch from an unpriviledged user, you may want to add a udev rule to grant all users access to the USB device:

```sh
$ sudo cp pkg/99-polar.rules /etc/udev/rules.d
$ sudo udevadm control --reload-rules
```


### macOS
Install the ruby language (>= 2.1) and dev tools, if necessary:

* install Xcode from the AppStore and Xcode Command Line Tools (`xcode-select --install`).
* install [Homebrew package manager](http://brew.sh)
* run `brew install ruby` to get the latest version of ruby

To connect to older watches (< Polar Ignite), macOS needs to be told not to attach it's default driver to the USB connection:

``` sh
$ sudo gem install hidapi
$ pkg/macos_usb
$ sudo kextunload -b com.apple.driver.usb.IOUSBHostHIDDevice
```

Unplug the watch if already connected, and plug it again.


### Windows
Install the ruby language (>= 2.1):
* [RubyInstaller](http://rubyinstaller.org). Pick the 32 bits (not x64) version - Ruby 2.3 works fine.

To connect to the watch, you need the `libusb-1.0.dll` DLL:

* copy the one provided in `pkg\libusb-1.0.dll` to `C:\Windows\SYSTEM32`
* _or_ download it from [libusb.info](http://libusb.info) (extract the 7-Zip archive, and use the DLL found in MinGW32\dll)


*NOTE*: use the Windows command line (`cmd`) to run the Ruby programs included in this project.

Example:

```
C:\Users\...> C:\Ruby23\bin\ruby.exe C:\path\to\this\project\directory\polar_ftp DIR /

C:\Users\...> C:\Ruby23\bin\ruby.exe C:\path\to\this\project\directory\polar_ftp DIR /U/0/

C:\Users\...> C:\Ruby23\bin\ruby.exe C:\path\to\this\project\directory\polar_ftp SYNC

C:\Users\...> C:\Ruby23\bin\ruby.exe C:\path\to\this\project\directory\polar_training2tcx C:/Users/.../Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /temp/output.tcx
```



## Installation (all platforms)
Install the Ruby gem dependencies:

```sh
$ bundle install
```

Download this repository and put it's content wherever you want (or use `git clone https://github.com/cmaion/polar` to clone it locally).


## Usage
List and download raw files from the Polar watch, connected through USB:

```sh
$ polar_ftp [options] DIR </path/to/directory>
$ polar_ftp [options] GET </path/to/file> [<output_file>]
$ polar_ftp [options] SYNC [</path/to/local/archive>]
```

Note: newer Polar watches talk over a USB serial device that should be exposed by the operating system. The device path is currently not auto-detected and should be specified using `-dDEVICE` option. This defaults to `-d/dev/ttyACM0` (usual case on Linux).

```sh
# Examples:
$ polar_ftp DIR /
Connected to Polar V800 serial XXXXXXXX
Listing content of '/'
   JOURNAL.DAT          10240
   PRODCONF.TXT            27
   SYS/
   U/
   SYSLOG.BPB              18
   MUSCF.BIN               12
   PRODDATA.BIN           152
   USAGECNT.BPB           110
   DEVICE.BPB             120
   SYNCINFO.BPB            79
$ polar_ftp -d/dev/ttyACM0 DIR /
Connected to Polar Vantage M serial XXXXXXXX
[...]
$ polar_ftp DIR /U/
[...]
$ polar_ftp DIR /U/0/
[...]
$ polar_ftp DIR /U/0/<YYYYMMDD>/
[...]
$ polar_ftp DIR /U/0/<YYYYMMDD>/E/
[...]
$ polar_ftp DIR /U/0/<YYYYMMDD>/E/<training_session_id>/
[...]
$ polar_ftp DIR /U/0/<YYYYMMDD>/E/<training_session_id>/00/
[...]

$ polar_ftp GET /U/0/<YYYYMMDD>/E/<training_session_id>/00/SAMPLES.GZB
Connected to Polar V800 serial XXXXXXXX
Downloading '/U/0/<YYYYMMDD>/E/<training_session_id>/00/SAMPLES.GZB' as 'SAMPLES.GZB'

$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
[...]
```


Convert user physical data to TXT file:

```sh
$ polar_physdata2txt <path/to/raw/polar/phys_data> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_physdata2txt ~/Polar/<device_id>/U/0/S/ /tmp/physdata.txt
$ polar_physdata2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/PHYSDATA/<snapshot_id>/ /tmp/physdata.txt
$ polar_physdata2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /tmp/physdata.txt
$ cat /tmp/physdata.txt
Snapshot date             : ...
Last modified             : YYYY-MM-DD HH:MM:SS +TZ00
Gender                    : ...
Birthday                  : ...
Weight                    : ...
Height                    : ...
HR max                    : ...
HR resting                : ...
Aerobic threshold         : ...
Anaerobic threshold       : ...
VO2max                    : ...
Training background       : ...
Typical day               : ...
Weekly recovery time sum  : ...
Functional threshold power: ...
```


Convert daily summary to TXT file:

```sh
$ polar_dailysummary2txt <path/to/raw/polar/daily_summary> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_dailysummary2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/DSUM/ /tmp/daily.txt
$ cat /tmp/daily.txt
Date                                : DD/MM/YYYY
Recorded activity                   : 24:00:00
Steps                               : 12000
Distance                            : 6841 m

BMR      calories                   : 1755 kcal
Activity calories                   :  427 kcal
Training calories                   : 1118 kcal
TOTAL    calories                   : 3300 kcal

Activity NON_WEAR                   : 01:27:00.000
Activity SLEEP                      : 08:41:30.000
Activity SEDENTARY                  : 08:43:00.000
Activity LIGHT                      : 03:27:00.000
Activity CONTINUOUS_MODERATE        : 00:00:00.000
Activity INTERMITTENT_MODERATE      : 00:03:30.000
Activity CONTINUOUS_VIGOROUS        : 01:22:00.000
Activity INTERMITTENT_VIGOROUS      : 00:16:00.000
TOTAL activity time                 : 05:08:30

Activity goal                       : 291% (926.8/318.0)
Activity goal (time to go, standing): 00:00:00.000
Activity goal (time to go, walking) : 00:00:00.000
Activity goal (time to go, running) : 00:00:00.000
```


Convert daily activity samples to CSV file:

```sh
$ polar_activitysamples2csv <path/to/raw/polar/daily_activity_samples> [<output_csv_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_activitysamples2csv ~/Polar/<device_id>/U/0/<YYYYMMDD>/ACT/ /tmp/daily.csv
$ cat /tmp/daily.csv
Time,Activity,Steps,Metabolic equivalent,Sport,Inactivity notification
[...]
YYYY-MM-DD 09:53:00 +0100,SEDENTARY,2,1.25,-1,
YYYY-MM-DD 09:53:30 +0100,SEDENTARY,,1.5,-1,
YYYY-MM-DD 09:54:00 +0100,LIGHT,20,1.75,-1,
YYYY-MM-DD 09:54:30 +0100,LIGHT,,2.0,-1,
YYYY-MM-DD 09:55:00 +0100,LIGHT,22,2.75,-1,
YYYY-MM-DD 09:55:30 +0100,LIGHT,,2.375,-1,
YYYY-MM-DD 09:56:00 +0100,LIGHT,20,2.625,-1,
YYYY-MM-DD 09:56:30 +0100,LIGHT,,2.375,-1,
YYYY-MM-DD 09:57:00 +0100,LIGHT,28,2.25,-1,
YYYY-MM-DD 09:57:30 +0100,LIGHT,,2.25,-1,
YYYY-MM-DD 09:58:00 +0100,INTERMITTENT_VIGOROUS,108,3.125,-1,
YYYY-MM-DD 09:58:30 +0100,INTERMITTENT_VIGOROUS,,10.25,1,
YYYY-MM-DD 09:59:00 +0100,INTERMITTENT_VIGOROUS,85,9.75,1,
YYYY-MM-DD 09:59:30 +0100,INTERMITTENT_VIGOROUS,,9.0,1,
YYYY-MM-DD 10:00:00 +0100,INTERMITTENT_VIGOROUS,100,9.75,1,
YYYY-MM-DD 10:00:30 +0100,INTERMITTENT_VIGOROUS,,10.375,1,
YYYY-MM-DD 10:01:00 +0100,INTERMITTENT_VIGOROUS,100,10.25,1,
YYYY-MM-DD 10:01:30 +0100,INTERMITTENT_VIGOROUS,,10.0,1,
YYYY-MM-DD 10:02:00 +0100,INTERMITTENT_VIGOROUS,89,9.75,1,
YYYY-MM-DD 10:02:30 +0100,INTERMITTENT_VIGOROUS,,10.5,1,
YYYY-MM-DD 10:03:00 +0100,CONTINUOUS_VIGOROUS,85,10.625,1,
YYYY-MM-DD 10:03:30 +0100,CONTINUOUS_VIGOROUS,,10.375,1,
YYYY-MM-DD 10:04:00 +0100,CONTINUOUS_VIGOROUS,87,10.25,1,
[...]
```


Convert a training session to Garmin GPX file:

```sh
$ polar_training2gpx <path/to/raw/polar/training_session_id> [<output_gpx_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_training2gpx ~/Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /tmp/output.gpx
```


Convert a training session to Garmin TCX file:

```sh
$ polar_training2tcx <path/to/raw/polar/training_session_id> [<output_rcx_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_training2tcx ~/Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /tmp/output.tcx
```


Convert a training session to Suunto SML file:

```sh
$ polar_training2sml <path/to/raw/polar/training_session_id> [<output_sml_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_training2sml ~/Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /tmp/output.sml
```


Read fitness test result and convert to TXT file:

```sh
$ polar_fitnesstest2txt <path/to/raw/polar/fitness_test_result> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_fitnesstest2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/FT/<fitness_test_id>/ /tmp/output.txt
```


Read RR recording result and convert to TXT file:

```sh
$ polar_rrrecord2txt <path/to/raw/polar/rr_record_result> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_rrrecord2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/RRREC/<rr_record_id>/ /tmp/output.txt
```


Read sleep analysis report and convert to TXT file:

```sh
$ polar_sleepanalysis2txt <path/to/raw/polar/sleep> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_sleepanalysis2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/SLEEP /tmp/output.txt
```


Read daily training load report (TRIMP, acute and chronic loads) and convert to TXT file:

```sh
$ polar_dailytrainingload2txt <path/to/raw/polar/daily_training_load> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_dailytrainingload2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/TL /tmp/output.txt
```


Read daily Nightly Recharge report (ANS) and convert to TXT file:

```sh
$ polar_nightlyrecharge2txt <path/to/raw/polar/nightly_recharge> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_nightlyrecharge2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/NR /tmp/output.txt
```


## Known issues
For now, only the first activity of a multisport training session (eg, triathlon) is exported by the SML/GPX/TCX converters.


## Author
[Cédric Maïon](https://github.com/cmaion)


## Credits
* [bipolar](https://github.com/pcolby/bipolar) for the initial inspiration
* [v800 downloader](https://github.com/profanum429/v800_downloader) for the initial USB protocol
* [loophole](https://github.com/rsc-dev/loophole) for the .proto files

## License
GPL3
