function CompareSettings([PSObject] $setting, $propertyNames) {
    $prop1 = $setting.PsObject.Properties[$propertyNames[0]].Value

    for ($num = 1 ; $num -le ($propertyNames.Count - 1); $num++) {
        $prop2 = $setting.PsObject.Properties[$propertyNames[$num]].Value

        if ($prop1 -ine $prop2) {
            return 1
        }    
        $prop1 = $prop2
    }

    return "";
}