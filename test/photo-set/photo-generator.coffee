child_process = require('child_process')
numeral       = require('numeral')
fs            = require('fs')

numeral.language 'fr',
    delimiters:
        thousands : ' '
        decimal   : ','
    abbreviations:
        thousand: 'k'
        million: 'm'
        billion: 'b'
        trillion: 't'
    currency:
        symbol: '€'

numeral.language('fr');

MONTHS = [
                nPhotos : 3 , month   : "201504"
            ,
                nPhotos : 2 , month   : "201503"
        ]


MONTHS = [
            {nPhotos : 3  , month : '201504'},
            {nPhotos : 17 , month : '201503'},
            {nPhotos : 3  , month : '201502'},
            {nPhotos : 17 , month : '201501'},
            {nPhotos : 3  , month : '201412'},
            {nPhotos : 17 , month : '201411'},
            {nPhotos : 3  , month : '201410'},
            {nPhotos : 17 , month : '201409'},
            {nPhotos : 3  , month : '201408'},
            {nPhotos : 17 , month : '201407'},
            {nPhotos : 3  , month : '201406'},
            {nPhotos : 17 , month : '201405'},
            {nPhotos : 3  , month : '201404'},
            {nPhotos : 17 , month : '201403'},
            {nPhotos : 3  , month : '201402'},
            {nPhotos : 17 , month : '201401'},
            {nPhotos : 3  , month : '201312'},
            {nPhotos : 17 , month : '201311'},
            {nPhotos : 3  , month : '201310'},
            {nPhotos : 17 , month : '201309'},
            {nPhotos : 3  , month : '201308'},
            {nPhotos : 17 , month : '201307'},
            {nPhotos : 3  , month : '201306'},
            {nPhotos : 17 , month : '201305'},
            {nPhotos : 3  , month : '201304'},
            {nPhotos : 17 , month : '201303'},
            {nPhotos : 3  , month : '201302'},
            {nPhotos : 17 , month : '201301'},
            {nPhotos : 3  , month : '201212'},
            {nPhotos : 17 , month : '201211'},
            {nPhotos : 3  , month : '201210'},
            {nPhotos : 17 , month : '201209'},
            {nPhotos : 3  , month : '201208'},
            {nPhotos : 17 , month : '201207'},
            {nPhotos : 3  , month : '201206'},
            {nPhotos : 17 , month : '201205'},
            {nPhotos : 3  , month : '201204'},
            {nPhotos : 17 , month : '201203'},
            {nPhotos : 3  , month : '201202'},
            {nPhotos : 17 , month : '201201'}
        ]
              #   ,
              #       nPhotos : 30 , month   : "201409"
              #   ,
              #       nPhotos : 30 , month   : "201408"
              #   ,
              #       nPhotos : 400 , month   : "201407"
              #   ,
              #       nPhotos : 1200 , month   : "201406"
              #   ,
              #       nPhotos : 30 , month   : "201405"
              #   ,
              #       nPhotos : 300 , month   : "201404"
              #   ,
              #       nPhotos : 100 , month   : "201403"
              #   ,
              #       nPhotos : 600 , month   : "201402"
              #   ,
              #       nPhotos : 300 , month   : "201401"
              #   ,
              #       nPhotos : 300 , month   : "201312"
              #   ,
              #       nPhotos : 300 , month   : "201311"
              #   ,
              #       nPhotos : 300 , month   : "201310"
              #   ,
              #       nPhotos : 300 , month   : "201309"
              #   ,
              #       nPhotos : 300 , month   : "201308"
              #   ,
              #       nPhotos : 300 , month   : "201307"
              #   ,
              #       nPhotos : 300 , month   : "201306"
              #   ,
              #       nPhotos : 300 , month   : "201305"
              #   ,
              #       nPhotos : 300 , month   : "201304"
              #   ,
              #       nPhotos : 300 , month   : "201303"
              #   ,
              #       nPhotos : 300 , month   : "201302"
              #   ,
              #       nPhotos : 300 , month   : "201301"
              #   ,
              #       nPhotos : 300 , month   : "201212"
              #   ,
              #       nPhotos : 300 , month   : "201211"
              #   ,
              #       nPhotos : 300 , month   : "201210"
              #   ,
              #       nPhotos : 300 , month   : "201209"
              #   ,
              #       nPhotos : 300 , month   : "201208"
              #   ,
              #       nPhotos : 300 , month   : "201207"
              #   ,
              #       nPhotos : 300 , month   : "201206"
              #   ,
              #       nPhotos : 300 , month   : "201205"
              #   ,
              #       nPhotos : 300 , month   : "201204"
              #   ,
              #       nPhotos : 300 , month   : "201203"
              #   ,
              #       nPhotos : 30 , month   : "201202"
              #   ,
              #       nPhotos : 30 , month   : "201201"
              # ]

spawn = require('child_process').spawn

startRk = 0
# child_process.execSync("mkdir photo")
for month, monthRk in MONTHS
    child_process.execSync("mkdir photo/#{month.month}")
    yearString  = month.month.slice(0,4)
    monthString = month.month.slice(-2)
    monthLabel  = yearString + '-' + monthString
    lastDayOfMonth = new Date(yearString, monthString,28).getTime()

    for localRk in [0..month.nPhotos-1] by 1
        file = "photo/#{month.month}/photo-#{month.month}-#{localRk}.gif"
        cmd  = "convert -size 300x300 -background lightblue -fill blue -pointsize 40 "
        cmd += "label:'"
        cmd += "rk: \n"
        cmd += "local rk:\n"
        cmd += "month rk:\n"
        cmd += "month:\n"
        cmd += "' "
        cmd += "-background none -gravity northeast label:'"
        cmd += "#{numeral(startRk+localRk).format('0,0')}\n"
        cmd += "#{numeral(localRk).format('0,0')}\n"
        cmd += "#{monthRk}\n"
        cmd += "#{yearString}-#{monthString}"
        cmd += "' -flatten #{file}"
        child_process.execSync(cmd)
        date = new Date(lastDayOfMonth-localRk*60000)
        fs.utimes(file,date,date)

    startRk += localRk

# convert -size 320x100 -background lightblue -fill blue -pointsize 18 label:'rk: 12365\nlocal rk:123\n2014-11' label.gif