[CmdletBinding()]
param (
    [switch] $startOver,
    #[string] $include,
    [array]  $exclude,
    [string] $first,
    [string] $second,
    [string] $third,
    [string] $fourth,
    [string] $fifth
)

begin {
    Clear-Host
    # Forcing the temp workng copy of wordle master list to repopulate
    if ($startOver.IsPresent) {
        Write-Verbose "startOver switch passed - copying full populated wordle list to temp"
        Copy-Item -Path .\words.txt -Destination $env:TEMP\tempWordle.txt -Force
        Write-Host -ForegroundColor White -BackgroundColor black 'Starting over with fresh copy of word list'
        if ($PSBoundParameters.Count -eq 1) {
            break
        }
    }

    if(-not(test-path -Path $env:TEMP\tempWordle.txt)) {
        # This Must be a first run of the script - need to create a working copy
        #   of the master list of Wordle words
        Copy-Item -Path .\words.txt -Destination $env:TEMP\tempWordle.txt
    } else {
        # Not the first run - is this a new day and new Wordle attempt?
        $today = Get-Date
        $d = (Get-Item $env:TEMP\tempWordle.txt).LastWriteTime
        if ($d.DayOfYear -eq $today.DayOfYear) {
            Write-Verbose "temp file is today"
        } else {
            Write-Verbose "temp file is not today - creating new copy to work with"
            Copy-Item -Path .\words.txt -Destination $env:TEMP\tempWordle.txt -Force
        }
    }

    # K - let's pull the content from the temp daily working copy of master list
    $ww = Get-Content $env:TEMP\tempWordle.txt
    write-host -ForegroundColor White -BackgroundColor Blue "Starting with $($ww.count) possible words"
    Write-Host
    # Create a temp ArrayList so we can use add and remove methods
    [System.Collections.ArrayList]$tww = @()
    # populate the temporary array list of all words found in our tempWordle.txt
    foreach ($w in $ww) {
        $null = $tww.Add($w)
    }
    # if ($include) {
    #     [System.Collections.ArrayList]$include = $include.ToCharArray()
    # } else {
    #     [System.Collections.ArrayList]$include = @()
    # }
}

process {

    function filterByPosition {
        [CmdletBinding()]
        Param (
            [int]$pos,
            [string]$letter
        )
        $l = $letter.Substring($letter.Length -1)
        $sww = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($tww))
        switch ($letter.Substring(0,1)) {
            'i' { 
                $workType = 'include'
            }
            'n' {
                $workType = 'exclude'
            }
        }

        foreach ($w in $sww) {
            if ($w -notmatch $l) {
                $null = $tww.remove($w)
            }
            if ($workType -eq 'include') {
                if (-not($w.Substring(($pos -1),1) -eq $l)) {
                    $null = $tww.remove($w)
                }
            } else {
                if ($w.Substring(($pos -1),1) -eq $l) {
                    $null = $tww.remove($w)
                }
            }
        }
        write-host -ForegroundColor Green "`t- filtered down to $($tww.count) possible words"
    }

    Write-Verbose "doing process"

    # Need to exclude words from the list since it would be rare to get correct word guess on first try
    if ($exclude) {
        # Need to make a new copy of the arraylist - not just an object that references the original arraylist
        # Since this is excluding any word with given letter - we don't need to reinitalize tww every time - just this time
        $sww = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($tww))
        [array]$exclude = $exclude.ToCharArray()
        foreach ($e in $exclude) {
            foreach ($w in $sww) {
                if ($w -match $e) {
                    $tww.Remove($w) | out-null
                }
            }
            Write-host -ForegroundColor Red "(-) excluding $e - filtered down to $($tww.count) possible words"
        }
    }

    if ($first) {
        $letter = $first.Substring($first.Length -1)
        if ($first.Substring(0,1) -eq 'i') {
            write-output "1st letter must be: $letter"
        } else {
            write-output "1st letter NOT: $letter"
        }
        filterByPosition -pos 1 -letter $first
    }
    if ($second) {
        $letter = $second.Substring($second.Length -1)
        if ($second.Substring(0,1) -eq 'i') {
            write-output "2nd letter must be: $letter"
        } else {
            write-output "2nd letter NOT: $letter"
        }
        filterByPosition -pos 2 -letter $second
    }
    if ($third) {
        $letter = $third.Substring($third.Length -1)
        if ($third.Substring(0,1) -eq 'i') {
            write-output "3rd letter must be: $letter"
        } else {
            write-output "3rd letter NOT: $letter"
        }
        filterByPosition -pos 3 -letter $third
    }
    if ($fourth) {
        $letter = $fourth.Substring($fourth.Length -1)
        if ($fourth.Substring(0,1) -eq 'i') {
            write-output "4th letter must be: $letter"
        } else {
            write-output "4th letter NOT: $letter"
        }
        filterByPosition -pos 4 -letter $fourth
    }
    if ($fifth) {
        $letter = $fifth.Substring($fifth.Length -1)
        if ($fifth.Substring(0,1) -eq 'i') {
            write-output "5th letter must be: $letter"
        } else {
            write-output "5th letter NOT: $letter"
        }
        filterByPosition -pos 5 -letter $fifth
    }

    # Add words that only include the letters specified, this is an AND list, not and/or
    # if($include) {
    #     $include
    #     foreach ($i in $include) {
    #         # Need to make a new copy of the arraylist - not just an object that references the original arraylist
    #         $sww = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($tww))
    #         foreach ($w in $sww) {
    #             if ($w -notmatch $i) {
    #                 $tww.Remove($w) | out-null
    #             }
    #         }
    #     }
    #     write-host -ForegroundColor DarkGreen "(+) including $i - filtered down to $($tww.count) possible words"
    # }
}

end {
    $tww | out-file -FilePath $env:TEMP\tempWordle.txt -Force
    Write-Verbose "doing end"
    Write-Host
    if ($tww.count -gt 25) {
        write-host -ForegroundColor DarkYellow "Filtered down to $($tww.count) words - to many to display"
    } else { 
        write-output "Filtered down to $($tww.count) words:"
        write-output "====="
        $tww
        write-output "====="
        #for (1...3) { write-output "" }
    }
}
