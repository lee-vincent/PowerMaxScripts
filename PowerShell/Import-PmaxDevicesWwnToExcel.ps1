Param(
  $csvFile = ".\PmaxDeviceWwnData.csv",
  $path = "C:\Users\Vinnie\OneDrive - AHEAD\__Customers\Fresenius Medical\PMAX Scripts\output.xlsx"
)

# i need to get the powermax device i_wwn e_wwn into csv format
$processes = Import-Csv -Path $csvFile


[xml]$devs=Get-Content .\dev_wwn.xml
$devices = $devs.SymCLI_ML.Symmetrix.Device

$output="Volume,Internal_wwn,External_wwn`n"
foreach ($device in $devices) {
  $dev_name = $device.Dev_Info.dev_name
  $wwn = $device.Product.wwn
  $e_wwn = $device.Device_External_Identity.wwn
  $output+="$dev_name,$wwn,$e_wwn`n"
}
$output


# $Excel = New-Object -ComObject excel.application
# $Excel.visible = $false
# $workbook = $Excel.workbooks.add()
# $excel.cells.item(1,1) = "Volume"
# $excel.cells.item(1,2) = "Internal_wwn"
# $excel.cells.item(1,3) = "External_wwn"
# $i = 2
# foreach($process in $processes)
# {
#  $excel.cells.item($i,1) = $process.Volume
#  $excel.cells.item($i,2) = $process.Internal_wwn
#  $excel.cells.item($i,3) = $process.External_wwn
#  $i++
# } #end foreach process
# $workbook.saveas($path)
# $Excel.Quit()
# Remove-Variable -Name excel
# [gc]::collect()
# [gc]::WaitForPendingFinalizers()
