###############################################################################
# This script was originally created by Vincent Lee of AHEAD to demonstrate
# a method for programmatically generating csv data files by querying Dell EMC 
# VMAX/PowerMax arrays using read-only symcli commands. 
#
# Tested 11-3-21 with Symmetrix Command Line Interface (SYMCLI) 
# Version V9.2.1.0 (Edit Level: 2622)
# built with SYMAPI Version V9.2.1.0 (Edit Level: 2622)
# PowerShell version 5.1.19041.1023
# Windows 10 Build 10.0.19041.1023
#
# This has not be tested in a production environment and by using this
# script you are agreeing to and assuming all responsibility related to its outcome.
###############################################################################
  
  
  <#
  .SYNOPSIS
  Save Volume, WWN, and External WWN information from the VMAX/PowerMax array specified by Sid into csv format

  #>


  Param(
    [Parameter(Mandatory=$false)]
    [string]$ReportName = "$env:temp\PmaxDeviceWwnData-$(get-date -Format MM_dd_yyyy__HH_mm_ss).csv",
    [Parameter(Mandatory=$true)]
    [string]$Sid
  )
  
  $ErrorActionPreference = "Stop"
  
  # https://www.powershellbros.com/create-table-function-working-data-tables-powershell/
  # Version : 1.2
  # Author : Lipinski, Grzegorz
  # Date : August 3, 2017
  function Create-Table {
    #region Parameters
        param(
            [Parameter(Mandatory=$true)]
            [string]$TableName,
            [Parameter(Mandatory=$true)]
            $ColumnNames
        )
  
    # Validate ColumnNames data type
        if ($ColumnNames.GetType().Name -eq "String") {
            $ColumnNames = $ColumnNames -split "," #convert provided string to array
        } elseif ($ColumnNames.GetType().BaseType.Name -ne "Array") {
            Write-Error "ColumnNames parameters accepts only String or Array value."
            break
        }
  
    # Set variables
        $TempTable = New-Object System.Data.DataTable
        $Count = 0
  
    # Temp Table construction
        if ($ColumnNames.count -ne 0) {
            do {
                Remove-Variable -Name datatype -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                $TempTable.Columns.Add() | Out-Null #add a column to the Temp Table
                # if data type specified for current column
                    if ($ColumnNames[$Count] -like "*/?*") {
                        $datatype = $ColumnNames[$Count].Substring($ColumnNames[$Count].IndexOf("/?")+2)
                        $ColumnNames[$Count] = $ColumnNames[$Count].Substring(0,$ColumnNames[$Count].IndexOf("/?"))
                        if ($datatype -notlike "System.*") {
                            $datatype = "System."+$datatype
                        }
                        $TempTable.Columns[$Count].DataType = $datatype
                    }
  
                $TempTable.Columns[$Count].ColumnName = $ColumnNames[$Count] # set Temp Table empty column Name
                $TempTable.Columns[$Count].Caption = $ColumnNames[$Count] # set Temp Table empty column Caption
                $Count++ # change Count + 1 to select next Column Name to add into the Temp Table
            } until ($Count -eq $ColumnNames.Count)
        }
  
    # Copy created Temp Table to the table with a name created by user and remove Temp Table
        Set-Variable -Name $TableName -Scope Global -Value (New-Object System.Data.DataTable)
        Set-Variable -Name $TableName -Scope Global -Value $TempTable
        Remove-Variable -Name TempTable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
  }
  
  # set symcli output mode to xml
  Set-Item -path env:SYMCLI_OUTPUT_MODE -Value 'XML'
  
  # save array configuration into xml variable
  [xml]$symdev_xml = symdev list -sid $Sid -v
  
  if (-not $?)
  {
      throw "Check Symmetrix ID $Sid`nsymdev list -sid $Sid -v"
  }
  
  # save just the device configurations 
  $devices = $symdev_xml.SymCLI_ML.Symmetrix.Device
  
  # loop over all devices and save volume ID, internal wwn, external wwn in csv format
  Create-Table -TableName DeviceTable -ColumnNames Volume,Internal_wwn,External_wwn
  foreach ($device in $devices) {
    $dev_name = $device.Dev_Info.dev_name
    $wwn = $device.Product.wwn
    $e_wwn = $device.Device_External_Identity.wwn
    $DeviceTable.Rows.Add($dev_name,$wwn,$e_wwn) | Out-Null
  }
  
  
  $DeviceTable | Export-Csv $ReportName -NoTypeInformation -Force -Encoding "ASCII"
  $ReportPath = Get-ChildItem $ReportName | Select-Object -ExpandProperty FullName
  Write-Host "Report saved to $ReportPath"
  
  # unset symcli xml output mode
  Remove-Item -path env:SYMCLI_OUTPUT_MODE
  
  