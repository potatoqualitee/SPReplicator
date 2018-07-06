function Invoke-ParseResultSet ($ResultSet) {
    foreach ($result in $Results) {
        $id, $method, $null = $result.ID.Split(",")
        $errorword = switch ($result.ErrorCode) {
            '0x00000000' { "Success" }
            else { 'Failure' }
        }
        [pscustomobject]@{
            Method    = $method
            Result    = $errorword
            ErrorCode = $result.ErrorCode
        }
    }
}