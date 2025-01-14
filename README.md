# m3u-exporter
Bash tool to copy media files such as MP3s, linked in M3U (playlist) file to a given destination.

## Prerequisites

Requires installation of `exiftool`.

### M3U software

[VOX Music Player](https://vox.rocks/) for Mac users.

[Winamp Classic](https://www.winamp.com/downloads/) 🤭 for Windows users. 

### ID3 software

[Squeed](https://krizzli.xyz/squeed) for Mac users. Alternatively [Tagr 5](https://apps.apple.com/us/app/tagr-5/id1450308734).

## Usage
Use `./m3ue.sh [path to M3U file] [path to destination] [flags]`.

The script will run the validation if all files have proper ID3 tags that will be used to generate filenames in destination directory.

After validation complete it will copy all existing files to the destination.

### Flags:
 * `--skip` Skips files without ID3 tags
 * `--force` Forces file copying using a filename
 * `--dry` Dry run. No files will be copied
 * `--noverify` Skips verificiation.
