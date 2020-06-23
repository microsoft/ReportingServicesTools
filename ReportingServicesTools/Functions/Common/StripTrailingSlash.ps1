function StripTrailingSlash {
    param($t)

    if($t.endswith("/")) {
        $t.substring(0,$t.length-1)
    } else {
        $t
    }
}