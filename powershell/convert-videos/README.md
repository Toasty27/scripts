# Usage

Designed for use with Video Insight, so expects a specific directory structure. Something like this:

```
videos
 \_ cam1
 |  \_ mm.dd.yyyy
 |  \_ mm.dd.yyyy
 |  \_ mm.dd.yyyy
 \_ cam2     
    \_ mm.dd.yyyy
    \_ mm.dd.yyyy
    \_ mm.dd.yyyy
```

You would, for example, run the script from the `cam1` directory. Then, the script will enter each directory in the `cam1` directory and convert all the videos, one by one.

### Notes
- Requires PS-Pushover module which is used for notifications (if you don't need notifications and don't want to install additional packages, search for `Notifications via Pushover` in the script and comment out the following four lines).
- Capable of restarting from last attempted transcode (script checks for a target bitrate and skips the file if target is met)
- Logs output to CSV