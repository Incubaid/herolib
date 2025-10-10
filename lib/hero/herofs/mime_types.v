module herofs

//see https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types

pub enum MimeType {
    aac
    abiword
    apng
    freearc
    avif
    avi
    azw
    bin
    bmp
    bz
    bz2
    cda
    csh
    css
    csv
    doc
    docx
    eot
    epub
    gz
    gif
    html
    ico
    ics
    jar
    jpg
    js
    json
    jsonld
    md
    midi
    mjs
    mp3
    mp4
    mpeg
    mpkg
    odp
    ods
    odt
    oga
    ogv
    ogx
    opus
    otf
    png
    pdf
    php
    ppt
    pptx
    rar
    rtf
    sh
    svg
    tar
    tiff
    ts
    ttf
    txt
    vsd
    wav
    weba
    webm
    manifest
    webp
    woff
    woff2
    xhtml
    xls
    xlsx
    xml
    xul
    zip
    gp3
    gpp2
    sevenz
}


pub fn mime_type_to_string(m MimeType) string {
    return match m {
        .aac { 'audio/aac' }
        .abiword { 'application/x-abiword' }
        .apng { 'image/apng' }
        .freearc { 'application/x-freearc' }
        .avif { 'image/avif' }
        .avi { 'video/x-msvideo' }
        .azw { 'application/vnd.amazon.ebook' }
        .bin { 'application/octet-stream' }
        .bmp { 'image/bmp' }
        .bz { 'application/x-bzip' }
        .bz2 { 'application/x-bzip2' }
        .cda { 'application/x-cdf' }
        .csh { 'application/x-csh' }
        .css { 'text/css' }
        .csv { 'text/csv' }
        .doc { 'application/msword' }
        .docx { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
        .eot { 'application/vnd.ms-fontobject' }
        .epub { 'application/epub+zip' }
        .gz { 'application/gzip' }
        .gif { 'image/gif' }
        .html { 'text/html' }
        .ico { 'image/vnd.microsoft.icon' }
        .ics { 'text/calendar' }
        .jar { 'application/java-archive' }
        .jpg { 'image/jpeg' }
        .js { 'text/javascript' }
        .json { 'application/json' }
        .jsonld { 'application/ld+json' }
        .md { 'text/markdown' }
        .midi { 'audio/midi' }
        .mjs { 'text/javascript' }
        .mp3 { 'audio/mpeg' }
        .mp4 { 'video/mp4' }
        .mpeg { 'video/mpeg' }
        .mpkg { 'application/vnd.apple.installer+xml' }
        .odp { 'application/vnd.oasis.opendocument.presentation' }
        .ods { 'application/vnd.oasis.opendocument.spreadsheet' }
        .odt { 'application/vnd.oasis.opendocument.text' }
        .oga { 'audio/ogg' }
        .ogv { 'video/ogg' }
        .ogx { 'application/ogg' }
        .opus { 'audio/ogg' }
        .otf { 'font/otf' }
        .png { 'image/png' }
        .pdf { 'application/pdf' }
        .php { 'application/x-httpd-php' }
        .ppt { 'application/vnd.ms-powerpoint' }
        .pptx { 'application/vnd.openxmlformats-officedocument.presentationml.presentation' }
        .rar { 'application/vnd.rar' }
        .rtf { 'application/rtf' }
        .sh { 'application/x-sh' }
        .svg { 'image/svg+xml' }
        .tar { 'application/x-tar' }
        .tiff { 'image/tiff' }
        .ts { 'video/mp2t' }
        .ttf { 'font/ttf' }
        .txt { 'text/plain' }
        .vsd { 'application/vnd.visio' }
        .wav { 'audio/wav' }
        .weba { 'audio/webm' }
        .webm { 'video/webm' }
        .manifest { 'application/manifest+json' }
        .webp { 'image/webp' }
        .woff { 'font/woff' }
        .woff2 { 'font/woff2' }
        .xhtml { 'application/xhtml+xml' }
        .xls { 'application/vnd.ms-excel' }
        .xlsx { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
        .xml { 'application/xml' }
        .xul { 'application/vnd.mozilla.xul+xml' }
        .zip { 'application/zip' }
        .gp3 { 'video/3gpp' }
        .gpp2 { 'video/3gpp2' }
        .sevenz { 'application/x-7z-compressed' }
    }
}


pub fn string_to_mime_type(s string) ?MimeType {
    return match s {
        'audio/aac' { .aac }
        'application/x-abiword' { .abiword }
        'image/apng' { .apng }
        'application/x-freearc' { .freearc }
        'image/avif' { .avif }
        'video/x-msvideo' { .avi }
        'application/vnd.amazon.ebook' { .azw }
        'application/octet-stream' { .bin }
        'image/bmp' { .bmp }
        'application/x-bzip' { .bz }
        'application/x-bzip2' { .bz2 }
        'application/x-cdf' { .cda }
        'application/x-csh' { .csh }
        'text/css' { .css }
        'text/csv' { .csv }
        'application/msword' { .doc }
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' { .docx }
        'application/vnd.ms-fontobject' { .eot }
        'application/epub+zip' { .epub }
        'application/gzip' { .gz }
        'image/gif' { .gif }
        'text/html' { .html }
        'image/vnd.microsoft.icon' { .ico }
        'text/calendar' { .ics }
        'application/java-archive' { .jar }
        'image/jpeg' { .jpg }
        'text/javascript' { .js }
        'application/json' { .json }
        'application/ld+json' { .jsonld }
        'text/markdown' { .md }
        'audio/midi' { .midi }
        'audio/mpeg' { .mp3 }
        'video/mp4' { .mp4 }
        'video/mpeg' { .mpeg }
        'application/vnd.apple.installer+xml' { .mpkg }
        'application/vnd.oasis.opendocument.presentation' { .odp }
        'application/vnd.oasis.opendocument.spreadsheet' { .ods }
        'application/vnd.oasis.opendocument.text' { .odt }
        'audio/ogg' { .oga }
        'video/ogg' { .ogv }
        'application/ogg' { .ogx }
        'font/otf' { .otf }
        'image/png' { .png }
        'application/pdf' { .pdf }
        'application/x-httpd-php' { .php }
        'application/vnd.ms-powerpoint' { .ppt }
        'application/vnd.openxmlformats-officedocument.presentationml.presentation' { .pptx }
        'application/vnd.rar' { .rar }
        'application/rtf' { .rtf }
        'application/x-sh' { .sh }
        'image/svg+xml' { .svg }
        'application/x-tar' { .tar }
        'image/tiff' { .tiff }
        'video/mp2t' { .ts }
        'font/ttf' { .ttf }
        'text/plain' { .txt }
        'application/vnd.visio' { .vsd }
        'audio/wav' { .wav }
        'audio/webm' { .weba }
        'video/webm' { .webm }
        'application/manifest+json' { .manifest }
        'image/webp' { .webp }
        'font/woff' { .woff }
        'font/woff2' { .woff2 }
        'application/xhtml+xml' { .xhtml }
        'application/vnd.ms-excel' { .xls }
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' { .xlsx }
        'application/xml' { .xml }
        'application/vnd.mozilla.xul+xml' { .xul }
        'application/zip' { .zip }
        'video/3gpp' { .gp3 }
        'video/3gpp2' { .gpp2 }
        'application/x-7z-compressed' { .sevenz }
        else { error('Unknown MIME type: $s') }
    }
}
