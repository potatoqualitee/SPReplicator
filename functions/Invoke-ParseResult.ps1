function Invoke-ParseResultSet ($ResultSet) {
    foreach ($result in $ResultSet) {
        $Id, $method, $null = $result.ID.Split(",")
        $errorword = switch ($result.ErrorCode) {
            '0x00000000' { "Success" }
            else { 'Failure' }
        }
        
        $row = ([xml]$result.OuterXml).Result.row
        if ($row) {
            [pscustomobject]@{
                Id = $row.ows_ID
                Title  = $row.ows_Title
                Method = $method
                Result = $errorword
                ErrorCode = $result.ErrorCode
            }
        }
        else {
            [pscustomobject]@{
                Id = $Id
                Method = $method
                Result = $errorword
                ErrorCode = $result.ErrorCode
            }
        }
    }
}