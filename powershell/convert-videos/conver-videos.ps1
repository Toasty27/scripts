Import-Module PS-Pushover

###
# User adjustable settings
###

# Log settings
$LOG_PATH = "C:\Users\Administrator\Documents\ConvertVideosLogs"

# Pushover user info (update with your token/user info)
$PO_TOKEN = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
$PO_USER = bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

# Pushover notification sounds
$PO_HIGH_START = "pushover" #Pushover sound for high-priority notification, used for transcoding start
$PO_HIGH_END = "echo"       #Pushover sound for high-priority notification, used for transcoding end
$PO_LOW = "bike"            #Pushover sound for low-priority notification

### END USER SETTINGS

###
# Set output formatting for custom object
###
$myType = "cctv.ConvertVideos"
$ddps = "Location","Name","Length","Original","Estimated","Converted","Corrupted"
if (-Not (Get-TypeData -TypeName $myType)) {
    Update-TypeData -TypeName $myType -DefaultDisplayPropertySet $ddps -Force
}

###
# Create log file in CSV format
###
$DATE = Get-Date -Format yyyyMMdd_HHmmss
$CAMERA = $pwd.Path.substring(3)
$LOG_FILE = "${LOG_PATH}\${CAMERA}-${DATE}.csv"

# Add header to log file
"" | select $ddps | Export-Csv $LOG_FILE -NoTypeInformation

$content = Get-Content $LOG_FILE
$content | Foreach {$n=1}{if ($n++ -ne 2) {$_}} > $LOG_FILE

###
# Define helper functions
###

# Notifications via Pushover
Set-PushoverSession -token $PO_TOKEN -user $PO_USER
function Notify-Admin( [String]$Title = "Operation Completed", [String]$Message = "", [String]$Sound = "pushover") {
    Send-PushoverMessage $Message -title $Title -sound $Sound
}

function Convert-Video( [String]$fileName ) {
    $file = $(Get-Item $fileName)
    $video = $fileName.substring(0,9)
    # No logging output, use x264 codec, 10FPS, 720p, 1500kbps, ultrafast encoding speed, AVI container format
    ffmpeg.exe -hide_banner -loglevel panic -i "$video.avi" -c:video libx264 -r:v 10 -s:v 1280x720 -b:v 1500k -preset ultrafast -f avi "$video.av2" | Wait-Process

    # Straight copy, no transcoding; For testing purposes only
#    ffmpeg.exe -hide_banner -loglevel panic -i "$video.avi" -c:video copy -f avi "$video.av2" | Wait-Process
}

function Get-AttributeData( [String]$fileName, [String]$AttributeName, [String]$MatchString ) {
    $file = $(Get-Item $fileName)

    $shellObject = New-Object -ComObject Shell.Application
    $AttributeIndex = 0

        # Get a shell object to retrieve file metadata.
        $directoryObject = $shellObject.NameSpace( $file.Directory.FullName )
        $fileObject = $directoryObject.ParseName( $file.Name )

        # Find the index of the attribute we're looking for, if necessary.
        for( $index = 5; -not $AttributeIndex; ++$index ) {
            $name = $directoryObject.GetDetailsOf( $directoryObject.Items, $index )
            if( $name -eq $AttributeName ) { $AttributeIndex = $index }
        }

        # Get the attribute value from the file metadata.
        $attributeString = $directoryObject.GetDetailsOf( $fileObject, $AttributeIndex )

        # Sanity check for presence of attribute (based on regex matching the expected value's format)
        if( $attributeString -match $MatchString ) { $success = $TRUE }
        else { $success = $FALSE }


    ###
    # Build Object to hold our metadata
    ###
    $Metadata = [PSCustomObject]@{
        Attribute = $AttributeName
        Value = $attributeString
        Success = $success        
    }

    return $Metadata
}

function main() {

Get-ChildItem . -filter '*.avi' | foreach {

    $file = $_
    $size = $_.Length

    $LengthValue = "Length"
    $LengthMatch = '\d\d:\d\d:\d\d'

    $BitrateValue = "Data rate"
    $BitrateMatch = '\d\d\d\dkbps'

###
# Get File Metadata
###
    # Get length of video
    $length = Get-AttributeData -fileName $file.Name -AttributeName $LengthValue -MatchString $LengthMatch
#    Write-Host -NoNewLine "Success:" $length.Success "Attribute:" $length.Attribute "Value:" $length.Value "`n"

###
# Check if file is corrupted 
###
    Write-Host -NoNewLine $file.Name 

    if ( -Not $length.Success ) {
        Write-Host -NoNewLine -ForegroundColor DarkGray " - "
        Write-Host -ForegroundColor Red  "File corrupted, not transcoding.`n"

        ###
        # Log info on corrupted video
        ###

        # Create custom Powershell object for video info
        $VideoInfo = [PSCustomObject]@{
            Location = $pwd
            Name = $file.Name
            Length = "0"
            Original = $file.Length
            Estimated = "Unknown"
            Converted = "Unknown"
            Corrupted = $TRUE 
        }

        $VideoInfo.psobject.TypeNames.Insert(0,"cctv.ConvertVideos")

        # Log video info to CSV 
        Export-Csv $LOG_FILE -InputObject $VideoInfo -Append

        return
    }

###
# Check if file is not necessary (avg bitrate <= ~1500kbps)
###
    # Get length of video in seconds
    $timeString = $length.Value
    $timespan = [TimeSpan]::Parse($timeString)
    $seconds = $timespan.TotalSeconds

    # Get bitrate from metadata (unreliable, left for posterity)
    #$bitrate = Get-AttributeData -fileName $file.Name -Attribute $BitrateValue -MatchString $BitrateMatch
    #$bitrateNum = $bitrate.Value.substring(1,4)

    # Calculate average bitrate based on file size and video length (metadata is unreliable)
    $bitrateAvg = [math]::round( $($file.Length * 8 / $seconds / 1000) )

    # 50kbps of wiggle room
    if ( $bitrateAvg -lt 1550 ) { 
        Write-Host -NoNewLine -ForegroundColor DarkGray " - "        
        Write-Host -ForegroundColor Yellow "File already converted, skipping.`n"
        return
    }

###
# Operate on files 
###
    # Estimate new size based on video length and new bitrate
    $estSize = $seconds * 1500000 / 8

    # Format data and output to console
    $sizeFMT = [math]::round( $($size / 1024 / 1024), 2)
    $estSizeFMT = [math]::round( $($estSize / 1024 / 1024), 2)

    Write-Host -NoNewLine -ForegroundColor DarkGray " - Length: "
    Write-Host -NoNewLine -ForegroundColor Cyan $length.Value 
    Write-Host -NoNewLine -ForegroundColor DarkGray " - Sizes ~ Original: "
    Write-Host -NoNewLine -ForegroundColor Cyan $sizeFMT
    Write-Host -NoNewLine -ForegroundColor DarkGray "  Estimated: "
    Write-Host -ForegroundColor Cyan $estSizeFMT

    # Convert video
    Write-Host -NoNewLine -ForegroundColor DarkGray "Converting Video...."

        $conversionTimestamp = date
        $sw = [Diagnostics.Stopwatch]::StartNew() # Start stopwatch for ffmpeg transcoding time
        Convert-Video -fileName $file.Name | out-null
        $sw.Stop() #Stop stopwatch

    Write-Host -NoNewLine -ForegroundColor DarkGray "Done.  Time: " 
    Write-Host $sw.Elapsed

    # Get new file info
    $newFileName = $file.Name.substring(0,9)
    $newFile = $(Get-Item "$newFileName.av2")
    $newSizeFMT = [math]::round( $($newFile.Length / 1024 / 1024), 2)

    Write-Host -NoNewLine -ForegroundColor DarkGray "Transcoding completed, removing old file.               Converted Size: "
    
    # If new video file size is smaller than estimated, original video probably has missing or corrupted frames
    if ($newFile.Length -le $estSize) {
        Write-Host -ForegroundColor red $newSizeFMT`n
        $corrupted = $TRUE
    }
    else {
        Write-Host -ForegroundColor green $newSizeFMT`n
        $corrupted = $FALSE
    }

    # Remove old files and rename transcoded files
#    Move-Item $file erased/$file # For testing purposes only
    Remove-Item $file.Name
    Move-Item $newFile $file

###
# Log video conversion info
###
    # Create custom Powershell object for video info 
    $VideoInfo = [PSCustomObject]@{
        Location = $pwd
        Name = $file.Name
        Length = $length.Value
        Original = $file.Length
        Estimated = $estSize
        Converted = $newFile.Length
        Corrupted = $corrupted 
    }

    $VideoInfo.psobject.TypeNames.Insert(0,"cctv.ConvertVideos")

    # Log video info to CSV 
    Export-Csv $LOG_FILE -InputObject $VideoInfo -Append
}
}

$Title = "Starting Transcoding"
$Message = "Camera: $CAMERA"
Notify-Admin -Title $Title -Message $Message -Sound $PO_HIGH_START | out-null

Get-ChildItem . -Directory | foreach {
    cd $_

    Write-Host -BackgroundColor White -ForegroundColor DarkCyan "Folder: " $_.Name
    Write-Host -ForegroundColor DarkGray "----------"

    main

    $Title = "Folder Completed"
    $Message = "Folder: $($_.Name)"
    Notify-Admin -Title $Title -Message $Message -Sound $PO_LOW | out-null
    cd ..
}

$Title = "Finished Transcoding"
$Message = "Camera: $CAMERA"
Notify-Admin -Title $Title -Message $Message -Sound $PO_HIGH_END | out-null
