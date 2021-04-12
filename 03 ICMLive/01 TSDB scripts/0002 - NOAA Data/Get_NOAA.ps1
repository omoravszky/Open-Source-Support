﻿# NOAA CO-OPS API For Data Retrieval
# https://api.tidesandcurrents.noaa.gov/api/prod/
$NoaaUrl = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
# User defined variables
$DataPath = 'C:\TEMP\NOAA\'
$NoaaTMZ = 'GMT'                          # Timezone of incoming data
$NoaaDatum = 'MLLW'                       # Datum of incoming data
$NoaaUnits = 'English'                    # Units system
# Sites
# https://tidesandcurrents.noaa.gov/
$NoaaSites = @(                           # =< Add more sites as needed >=
    '8519483'                             # Bergen
    '8518750'                             # Battery
)
# Parameters
$ObsParams = @{                           # Parameters for Observed data (example)
    Period = 72                           # Time range of data (h)
    Type = 'Observed'                     # Type of data (observed / predicted)
    Product = 'water_level'               # Type of data
    Interval = '6'                        # Interval for which data is returned 
    Suffix = '_obs_'                      # Suffix for tagging CSV file
}
$ForParams = @{                           # Parameters for Forecast data (example)
    Period = 72                           # Time range of data (h)
    Type = 'Forecast'                     # Type of data (observed / predicted)
    Product = 'predictions'               # Type of data
    Interval = 'h'                        # Interval for which data is returned 
    Suffix = '_prs_'                      # Suffix for tagging CSV file
}
# Functions
# Generates a URL to download the data with origin rounded to the current hour
function Set-RestUrl {
    Param($Site, $Stream)
    $CurrentTime = (Get-Date).ToString("yyyyMMdd") + "%20" + (Get-Date).ToString("HH:00")
    if ($Stream.Type -eq 'Observed') { $StreamPeriod = "end_date={0}&range={1}" –f $CurrentTime, $Stream.Period }
    if ($Stream.Type -eq 'Forecast') { $StreamPeriod = "begin_date={0}&range={1}" –f $CurrentTime, $Stream.Period }
    $StringQuery = "{0}&station={1}&product={2}&datum={3}&time_zone={4}&interval={5}&units={6}&application=web_services&format=json" `
        –f $StreamPeriod, $Site, $Stream.Product, $NoaaDatum, $NoaaTMZ, $Stream.Interval, $NoaaUnits
    $NoaaUrl + '?' + $StringQuery

}
# Gets the data and converts it to Simple CSV tor TSDB consumption
function Get-Data {
    Param($Sites, $Stream, $Path)
    Foreach ($Site in $Sites) {
        $OutFile = ($Path + $Site + $Stream.Suffix + $Stream.Period + "hrs.csv")
        $Url = Set-RestUrl -Site $Site -Stream $Stream
        $json = Invoke-WebRequest -Uri $Url -UseBasicParsing | ConvertFrom-Json
        if ($Stream.Type -eq 'Observed') { $data = $json.data }
        if ($Stream.Type -eq 'Forecast') { $data = $json.predictions }
        $data | Select-Object t,v | ConvertTo-CSV -NoTypeInformation |
        Select-Object -Skip 1 | ForEach-Object {$_ -replace '"',''} |
        Out-File -encoding "ASCII" $OutFile
    }
}

# Create a path for the files if it doesn't exist
New-Item -ItemType Directory -Force -Path $DataPath | Out-Null
# Call Get-Data function
Get-Data -Sites $NoaaSites -Stream $ObsParams -Path $DataPath
Get-Data -Sites $NoaaSites -Stream $ForParams -Path $DataPath