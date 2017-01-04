## Synopsis
A set of tools written in Ruby to interact with Polar watches and decode raw data files.

* `polar_ftp`: access the Polar file system through USB
  * list content on the Polar watch
  * download raw files
  * backup complete content
* `polar2sml`: convert raw polar training sessions data files to the Suuntu SML file format

Tested with:
* Polar M200
* Polar V800
* might also work on other models (A360, M400, Loop...), but this is untested

Tested on Linux (Ubuntu 16.10).


## Installation
Install the ruby language and the following ruby gems:

```sh
$ gem install ruby-protocol-buffers
$ gem install varint   # Optional (increases ruby-protocol-buffers performance)
$ gem install libusb   # Required by polar_ftp
$ gem install zlib     # Required by polar2sml
$ gem install nokogiri # Required by polar2sml
```

Copy the content of this repository wherever you want.


To be able to connect to the watch on Linux from an unpriviledged user, you may want to add a udev rule to grant all users access to the USB device:

```sh
$ sudo cp pkg/99-polar.rules /etc/udev/rules.d
$ sudo udevadm control --reload-rules
```


## Usage
List and download single raw files from the Polar watch, connected through USB:

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

Conversion to Suunto SML:

```sh
$ polar2sml <path/to/raw/polar/training_session_id> [<output_sml_file>]

# Example:
$ polar_ftp SYNC # Copy watch file system to ~/Polar/<device_id>
$ polar2sml ~/Polar/<device_id>/U/0/<YYYYMMDD>/E/<training_session_id>/ /tmp/output.sml
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
