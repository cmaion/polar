## Synopsis
A set of command line tools written in Ruby to interact with Polar watches and decode raw data files.

* `polar_ftp`: access the Polar file system through USB
  * list content on the Polar watch
  * download raw files
  * backup complete content
* `polar_training2sml`: convert raw polar training sessions data files to the Suuntu SML file format
* `polar_rrrecord2txt`: displays content of RR recording results and exports to TXT file (V800)

Tested with:
* Polar M200
* Polar V800
* might also work on other models (A360, M400, Loop...), but this is untested

Tested on Linux (Ubuntu 16.10), macOS (Yosemite) and Windows (10).


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

To connect to the watch, macOS needs to be told not to attach it's default driver to the USB connection:

``` sh
$ sudo gem install hidapi
$ pkg/macos_usb
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

C:\Users\...> C:\Ruby23\bin\ruby.exe C:\path\to\this\project\directory\polar_training2sml C:/Users/.../Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /temp/output.sml
```



## Installation (all platforms)
Install the following Ruby gems:

```sh
$ gem install ruby-protocol-buffers
$ gem install varint   # Optional (increases ruby-protocol-buffers performance)
$ gem install libusb   # Required by polar_ftp
$ gem install nokogiri # Required by polar_training2sml
```

Download this repository and put it's content wherever you want (or use `git clone https://github.com/cmaion/polar` to clone it locally).


## Usage
List and download raw files from the Polar watch, connected through USB:

```sh
$ polar_ftp DIR </path/to/directory>
$ polar_ftp GET </path/to/file> [<output_file>]
$ polar_ftp SYNC [</path/to/local/archive>]

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

Convert a training session to Suunto SML file:

```sh
$ polar_training2sml <path/to/raw/polar/training_session_id> [<output_sml_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_training2sml ~/Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /tmp/output.sml
```


Read RR recording result and convert to TXT file:

```sh
$ polar_rrrecord2txt <path/to/raw/polar/rr_record_result> [<output_txt_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar_rrrecord2txt ~/Polar/<device_id>/U/0/<YYYYMMDD>/RRREC/<rr_record_id>/ /tmp/output.txt
```

## Author
[Cédric Maïon](https://github.com/cmaion)


## Credits
* [bipolar](https://github.com/pcolby/bipolar) for the initial inspiration
* [v800 downloader](https://github.com/profanum429/v800_downloader) for the initial USB protocol
* [loophole](https://github.com/rsc-dev/loophole) for the .proto files
* [Andrew Faraday](http://www.andrewfaraday.com/2015/08/reading-usb-controllers-in-ruby-or-what.html) for the sample Ruby USB code

## License
GPL3
