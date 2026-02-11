# Register Microsoft Update as a source
$UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager
$UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")

# Search for missing drivers
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
$Searcher.ServerSelection = 3 # Third Party Catalog
$SearchResult = $Searcher.Search("IsInstalled=0 and Type='Driver'")

# Display and Install
$SearchResult.Updates | Select-Object Title