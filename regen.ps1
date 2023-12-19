[System.Console]::Clear()
[String]$version = '20231219-03'
# Proto reGenerator
# regenerates class files for gRPC protoc
# this file should be located in the same dir with .proto files
#
# -[ Manual constant overrides ]--
[String]$file_name = ''
[String]$out_path = ''
[String]$plugin = ""

# -[ Initialization ]--
## /!\ WARNING! To use this script with another language like Java or Python
##  you MIGHT need to disable plugin check along with changing $lang_default
##  below to for example "--java_out"
[String]$lang_default = "--dart_out"
[bool]$plugin_check = $true
[String]$proto_path = Get-Location
[String]$plugin_default = "$env:LOCALAPPDATA\pub\cache\bin\protoc-gen-dart.bat"
[String]$out_path_default = "gen"
[bool]$multi_file = $false
[String]$protoc_app = "protoc.exe"

####
# -[ Functions ]--
# drawing characters
# found here: https://www.genelaisne.com/powershell-warnings-with-ascii-art/
$d_hor = [String][char]9552
$d_ver = [String][char]9553
$d_tl = [String][char]9556
$d_tr = [String][char]9559
$d_ml = [String][char]9568
$d_mr = [String][char]9571
$d_bl = [String][char]9562
$d_br = [String][char]9565

function gen_line{
    Param(
        [Parameter(Mandatory=$false)][String]$pos,
        [Parameter(Mandatory=$false)][int]$width,
        [Parameter(Mandatory=$false)][String]$msg
    )

    if($width -le 0) {
        $width = (Get-Host).UI.RawUI.MaxWindowSize.Width - 2
    }

    # render if there is a message
    if ($msg.Length -gt 0)
    {
        # split long message into multiple strings
        [int]$max_msg = $width - 2
        [array]$msg_array = @()
        if ($msg.Length -gt $max_msg) {
            $msg_array = $msg -split "(.{$max_msg})"
        } else {
            $msg_array += $msg
        }

        # render multi string message
        foreach($this_msg in $msg_array) {
            [String]$draw_line = $d_ver
            $draw_line += $this_msg
            for ([int]$c = 0; $c -lt ($width - $this_msg.Length); $c++) {
                $draw_line += " "
            }
            $draw_line += $d_ver

            Write-Host ($draw_line -Join " ")

        }

    } else {
        $start = $d_ver
        $end = $start
        if ($pos -eq "top") {
            $start = $d_tl
            $end = $d_tr
        } elseif ($pos -eq "med") {
            $start = $d_ml
            $end = $d_mr
        } elseif ($pos -eq "end") {
            $start = $d_bl
            $end = $d_br
        }

        [String]$draw_line = $start
        for($c = 0; $c -lt $width; $c++) {
            $draw_line += $d_hor
        }
        $draw_line += $end

        Write-Host $draw_line
    }

}

function array_pop{
    # remove elements from array
    Param(
        [Parameter(Mandatory=$true)][array]$array,
        [Parameter(Mandatory=$true)][array]$to_remove
    )

    [System.Collections.ArrayList]$temp = $array
    foreach($remove_me in $to_remove){
        $temp.Remove($remove_me)
    }
    return $temp
}

####
# -[ Start ]--
gen_line -Pos top
gen_line -msg " -[ Proto reGenerator v.$version ]--"
gen_line -msg "                     - geoai777@gmail.com 2023 -"
gen_line -Pos med

####
# -[ Check protoc executable ]--
if ((Get-Command $protoc_app -ErrorAction SilentlyContinue) -eq $null) {
    Write-Warning "$protoc_app - not found! Please install, specify full path or add folder with $protoc_app to PATH"
    Exit
}

####
# -[ Check pligin ]--
# if no plugin path defined in constants
if ($plugin_check) {
    [String]$protoc_gen = "protoc-gen-dart\.bat$"
    if ($plugin -notmatch $protoc_gen){
        gen_line -msg " (i) Using default plugin path"
        $plugin = $plugin_default
    }

    # check if dart plugin really exist
    if (-Not (Test-Path -Path $plugin)) {
        Write-Warning "Dart plugin not found at path: $plugin. Try correcting path or installing plugin"
        Exit
    }
}

####
# -[ Check .proto file ]--
# If no file name defined in constants
if ($file_name.Length -le 7) {

    # list files in current folder
    [array]$proto_files = @();
    $proto_files = Get-ChildItem -Filter *.proto

    # most frequent case - there is one file
    if ($proto_files.Count -eq 1) {
        $file_name = $proto_files[0]

    # less frequent - there are no files
    } elseif ($proto_files.Count -eq 0) {
        Write-Warning "[!] No proto files found in current folder!"

    # there are multiple files
    } else {
        [int]$choice = -2

        # request which file to use
        while(($choice -lt -1) -or ($choice -ge $proto_files.Count)) {
            gen_line -msg " There are following .proto files:"
            foreach ($file in $proto_files) {
                gen_line -msg "  [$([array]::IndexOf($proto_files, $file))] $file"
            }
            $choice = Read-Host "$d_ver Enter number or type '-1' to use all"
        }
        if ($choice -eq -1) {
            $multi_file = $true
        } else {
            $file_name = $proto_files[$choice]
        }
    }
}

# if single file found/specified
if (-Not $multi_file) {

    # check if NO file present and exit
    if (-Not (Test-Path -Path "$proto_path/$file_name")) {
        Write-Warning "Specified file $proto_path/$file_name not found. Try automatic mode or correct file name"
        Exit
    }
    $file_name = "$proto_path/$file_name"

# for multiple files
} else {
    [array]$proto_full_path = $proto_files;

    foreach ($file in $proto_full_path) {

        # remove element if it doesn't exist
        if (-Not (Test-Path -Path "$proto_path/$file")) {
            $proto_full_path = array_pop -array $proto_full_path -to_remove $file
        }
    }
    if ($proto_full_path.Count -le 0) {
        Write-Warning "There are no files at specified path, try correcting path/filenames"
        Exit
    } else {
        foreach($file in $proto_full_path) {
            $proto_full_path[[array]::IndexOf($proto_full_path, $file)] = "$proto_path/$file"
        }
    }
}

####
# -[ Check/create destination dir ]--
# if there is no dir name defined in constants
if ($out_path.Length -lt 1) {
    $out_path = $out_path_default
    gen_line -msg " (i) No default output dir specified setting to $out_path"
}

# absolute out_path
$out_path = "$proto_path/$out_path"

# check if path exists
if(-Not (Test-Path -Path $out_path)) {

    # create destination folder
    gen_line -msg " (+) Creating $out_path"
    [void](New-Item -ItemType Directory -Path $out_path)
}

# generate run command
$arg_cmd = @()
$arg_cmd += "--proto_path=$proto_path"
$arg_cmd += "--plugin=$plugin"
$arg_cmd += "$lang_default=$out_path"
if (-Not $multi_file) {
    $arg_cmd += $file_name
} else {
    foreach($full_path in $proto_full_path) {
        $arg_cmd += $full_path
    }
}


# make all slash and backslash same type
$arg_cmd = $arg_cmd.Replace('\', '/');

gen_line -msg " Running: protoc $arg_cmd"
& "$protoc_app" ($arg_cmd)
gen_line -pos end
