# Introducing the Martile gem

The Martile gem attempts to address some of the issues I have with Markdown using a variation of Textile.  It is intended that this gem is executed before it's processed as markdown.

    require 'martile'

    s = "
    # title1

    [# sun

        fun
        1234

    # run
    today
    # bun
    # pun]

    dd

        tttt
        rrrr
        ssss

    ee


    * an ordinary
    * list

    "


    html = Martile.new(s).to_html

## output

    # title1

    <ol><li>sun
    <pre><code>fun
    1234</code></pre></li><li>run
    today</li><li>bun</li><li>pun</li></ol>

    dd
    <pre><code>tttt
    rrrr
    ssss</code></pre>

    ee


    * an ordinary
    * list

## Resources

* [jrobertson/martile - GitHub](https://github.com/jrobertson/martile)
