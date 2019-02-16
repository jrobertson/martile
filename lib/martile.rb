#!/usr/bin/env ruby

# file: martile.rb

#require 'rexle-builder'
#require 'rexle'
#require 'kvx'
require 'yatoc'
require 'rqrcode'
#require 'dynarex'
#require 'rdiscount'
require 'mindmapdoc'
require 'flowchartviz'


# feature:  16-Feb-2019 A hidden field cam now be rendered using 
#                       the syntax [? name: value]                       
# feature:  11-Feb-2019 An apostrophe used between words is now preserved 
#                       from Kramdown HTML rendering
# feature:  23-Dec-2018 A SectionX or KVX object can now be referenced 
#                       from interpolated variables
# feature:  17-Dec-2018 Now automatically generates a toc when there are 3 
#                       sections or more
# feature:   3-Oct-2018 An embed tag can now be used to dynamically load content
# bug fix:  26-Sep-2018 An extra new line is added after a code block to 
#                       ensure the line directly below it is transformed to 
#                       HTML correctly.
# bug fix:  23-Sep-2018 mindmap tag is now properly 
#                       transformed before parse__data__
# feature:  23-Jul-2018 An HTML form can now be generated
# feature:  12-Feb-2018 Transforms <mindmap> tags into a 
#                       mindmap + related headings
# feature:   8-Feb-2018 A section attribute id can now include a dash (-).
#                       Markdown inside a section element is no longer 
#                       rendered by RDiscount
# minor improvement: 29-Sep-2017 A Markdownviz or Flowchartviz embedded 
#                 document can now be declared without the word viz at the end.
# feature:  21-Sep-2017 A qrcode can now be rendered 
#                         e.g. !q[](http://github.com)
# feature:  16-Sep-2017 A Flowchartviz raw document can now be embedded
# feature:   9-Sep-2017 A Mindmapviz raw document can now be embedded
# feature:   8-Sep-2017 An SVG doc can now be embedded from !s[]()
# feature:   6-Sep-2017 The preparation of a Dynarex table in Markdown is now 
#                       done from the Dynarex object
# bug fix:  13-Aug-2017  bug fixes: A markdown table is no longer interpreted 
#                       as <code> and a string containig a caret is no longer 
#                       interpreted as <nark> if it contains non 
#                       alphanumerical characters.
# feature:  28-May-2017  Within the context of an embedded Dynarex table, 
#  the nomarkdown extension was wrapped around the inner HTML for each column
#                        
#                        Return characters are now stripped out.
#
#                        An embeded Dynarex table contents are now rendered to 
#                        Markdown by default
# feature:  11-Mar-2017  A details and summary tag can now be generated from +> 
#                        e.g.
#                        !+
#                        This a paragraph
# 
#                        ----------------
#
#                        * something
#                        +
# minor feature:
#            9-Feb-2017  implemented a shorthand (^) for the mark tag



class Martile
  using ColouredText

  attr_reader :to_s, :to_html, :data_source

  def initialize(raw_s='', ignore_domainlabel: nil, debug: false, log: nil)


    @debug = debug
    @data_source = {}
    
    @ignore_domainlabel, @log = ignore_domainlabel, log

    raw_s.gsub!("\r",'')
    
    
    s10 = MindmapDoc.new(debug: debug).transform(raw_s)
    puts 's10: ' + s10.inspect if debug
    
    s20 = s10 =~ /^__DATA__$/ ? parse__data__(s10) : s10
    puts ('s20: ' + s20.inspect).debug if debug    
    
    s30 = apply_filter(s20) {|x| slashpre x }
    #puts 's1 : ' + s1.inspect
    s40 = apply_filter(s30) {|x| code_block_to_html(x.strip + "\n") }

    #puts 's2 : ' + s2.inspect
    #s3 = apply_filter(s2, %w(ol ul)) {|x| explicit_list_to_html x }
    #puts 's3 : ' + s3.inspect
    s50 = apply_filter(s40) {|x| ordered_list_to_html x }
    #puts 's4 : ' + s4.inspect

    s60 = apply_filter(s50) {|x| unordered_list_to_html x }
    #puts 's5 : ' + s5.inspect

    s70 = apply_filter(s60) {|x| dynarex_to_markdown x }
    #puts 's6 :' + s6.inspect

    s80 = apply_filter(s70) {|x| table_to_html x }
    #puts 's7 : ' + s7.inspect

    s90 = apply_filter(s80) {|x| underline x}
    puts 's90: ' + s90.inspect if @debug
    s100 = apply_filter(s90) {|x| section x }
    puts 's100: ' + s100.inspect if @debug
    
    s110 = apply_filter(s100) {|x| smartlink x }

    puts 's110: ' + s110.inspect if @debug

    #s11 = section s9
    #puts 's11 : ' + s11.inspect
    s120 = apply_filter(s110) {|x| audiotag x }
    #puts 's12 : ' + s12.inspect
    s130 = apply_filter(s120) {|x| videotag x }
    #puts 's13 : ' + s13.inspect
    s140 = apply_filter(s130) {|x| iframetag x }
    #puts 's14 : ' + s14.inspect
    s150 = apply_filter(s140) {|x| kvx_to_dl x }
    #puts 's15 : ' + s15.inspect
    s160 = apply_filter(s150) {|x| list_item_to_hyperlink x }
    s165 = apply_filter(s160) {|x| formify x }
    #puts 's16 : ' + s16.inspect
    s170 = apply_filter(s165) {|x| mtlite_utils x }
    s180 = apply_filter(s170) {|x| hyperlinkify x }
    s190 = apply_filter(s180) {|x| highlight x }
    s200 = apply_filter(s190) {|x| details x }
    s210 = apply_filter(s200) {|x| qrcodetag x }
    s220 = apply_filter(s210) {|x| svgtag x }
    s230 = apply_filter(s220) {|x| embedtag x }
    s240 = apply_filter(s230) {|x| script_out x }
    
    @to_s = s240
    
    s250 = apply_filter(s240) {|x| nomarkdown x }
    s260 = Yatoc.new(Kramdown::Document.new(s250).to_html, debug: debug).to_html
    puts ('s260: '  + s260.inspect).debug if debug    
    
    #puts 's17 : ' + s17.inspect
    
    @to_html = s260
    
  end
  
  def create_form(s)

    a = LineTree.new(s, ignore_blank_lines: true).to_a
        
    def create_form_input(raw_name)

      name = raw_name.downcase[/\w+/]
      type =  name =~ /password/ ? :password : :text

      ['div', {}, 
        ['label', {for: name}, raw_name], 
        ['input', {type: type, id: name, name: name}]
      ]
    end
    
    a2 = a[0][1..-1].select {|x| x[0] =~ /[^:]+\:/}.map do |items|
            
      line = items[0]
      case line
      when /^\w/
        create_form_input(line[/^\w[^:]+\:/])
      when /!/
        name, value = line.match(/\[\s*!\s+([^:]+):\s+([^\]]+)/).captures
        ['input', {type: 'hidden', name: name, value: value}]
      end
    end

    button_name, link = s.match(/\[([^\]]+)\]\(([^\)]+)\)/).captures

    a2 << ['div', {class: 'button'}, ['button', {type: 'submit'}, button_name]]

    a2.insert 0, 'form', {id: a[0][0], action: link, method: 'post'}
    doc = Rexle.new(a2)
    doc.root.element('div/input').attributes['autofocus'] = 'true'
    doc.xml pretty: true, declaration: false
    
  end
  

  private
  
  def audiotag(s)
    
    s.gsub(/\B!a\[\]\((https?:\/\/[^\)]+)\)\B/) do |x|
      
      files = ($1).split

      h = {/\.ogg$/ => 'ogg', /\.wav$/ => 'wav', /\.mp3$/ => 'mp3' }

      sources = files.map do |file|
        type = h.detect{|k,v| file[k] }.last
        "  <source src='%s' type='audio/%s'/>" % [file, type]
      end

      "<audio controls='controls'>\n%s\n</audio>" % [sources.join("\n")]
    end    

  end    

  def code_block_to_html(s)

    
    s.split(/(?=<pre>)/).map do |s2|      
      
      if s2[0] != '<' then
        
        s.lines.chunk {|x| x =~ /^\n|^    |\n/ }.map do |_, x| 

          if x.join.lstrip[/^    /] then
            "\n<pre><code>%s</code></pre>\n\n" % escape(x.join.gsub(/^ {4}/,''))
          else
            x.join
          end

        end.join

      else
        s2
      end
      
    end.join
      

  end

  def details(s)
    
    puts ('inside details: ' + s.inspect).debug if @debug
    
    s.split(/(?=\!\+)/).map do |x|
      
      if x =~ /\!\+/ then

        x[2..-1].sub(/(.*)[^\+]+\n\+/m) do |x2|

          summary, detail = x2.split(/----+/,2)
          "<details><summary>%s</summary>%s</details>" % [summary, detail.chop]

        end
        
      else
        x
      end
    end.join

  end
  
  def dynarex_to_markdown(s)
    
    s.gsub(/!d\[\]\(((#\w+|https?:\/\/)?[\w\/\.\-]+)\)(\{[^\}]+\})?/) do |match|

      source = ($1)
      raw_select = ($3)

      dx = if source =~ /^http/ then
        Dynarex.new(source)      
      else
        @data_source[source[/\w+/]]
      end

      if dx.fields.length > 1 then
        dx_render_table(dx, raw_select)
      else
        dx.records.keys.map {|x| '* ' + x}.join("\n")
      end
    end
  end

  def kvx_to_dl(s)

    s.gsub(/:(\[.*\])\(((?:https?:\/\/)?[\w\/\.\-]+)\)?/) do |match|

      source = ($1)
      raw_select = ($2)
      h = Kvx.new(raw_select).body

      a = h.map do |k,v|
        "<dt>%s</dt><dd>%s</dd>" % [k,v]
      end
      "<dl>" + a.join("\n") + "</dl>"
    end

  end
  
  def embedtag(s)
    
    s.gsub(/\B!\(((?:https?|rse|dfs):\/\/[^\)]+)\)/) do                         
      RXFHelper.read(source=($1)  ).first        
    end

  end
  
  
  def escape(s)
    s.gsub('<','&lt;').gsub('>','&gt;')
  end
  
  def formify(s)
    
    s.split(/(?=\n\w+)/).map do |s|
      
      if s =~ /(?=\w+\n\n*  \w+: +\[ +\])/ then
        create_form(s)
      else
        s
      end
      
    end.join
    
  end
  
  def iframetag(s)
    
    s.gsub(/\B!i\[\]\((https?:\/\/[^\)]+)\)\B/) do |x|
      
      url = ($1)

      "<iframe src='%s'></iframe>" % [url]
    end    

  end
  
  

  def list_to_html(s,symbol='#')

    return s unless s[/\[#{symbol}[^\]]+\]/]
    tag = {'#' => 'ol', '\*' => 'ul'}[symbol]

    s.split(/(?=\[#{symbol}|^#{symbol*2})/).map do |x|
      
      if x.strip.length > 0 then
        s2, remainder = [x[/\[#{symbol}.*#{symbol}[^\]]+\]/m], ($').to_s]
      end
      
      if s2 then

        raw_list = s2[1..-2].split(/^#{symbol}/).reject(&:empty?).map(&:strip)
        list = "<#{tag}>%s</#{tag}>" % raw_list.map {|x| \
                    "<li>%s</li>" % RDiscount.new(Martile.new(x, \
                  ignore_domainlabel: @ignore_domainlabel).to_html)\
                                             .to_html[/<p>(.*)<\/p>/,1]}.join
        list + remainder.to_s
        
      else
        
        x
        
      end
      
    end.join

  end
  
  def filter_on(s)

    @filter = []

    a = s.split(/(?=<pre)/).map.with_index do |row, i|
      
      row.sub(/<pre.*<\/pre>/m) do |pattern|
        placeholder = '!' + Time.now.to_i.to_s + i.to_s
        @filter << [placeholder, pattern]
        placeholder
      end

    end
    a.join
    
  end  
  
  def filter_off(raw_s)
    
    s = raw_s.clone
    @filter.each {|id, x| s.sub!(id, x) }
    return s

  end

  def apply_filter(s)
    
    s1 = filter_on(s)
    s2 = yield s1
    s3 = filter_off s2
    
    return s3
  end
  

  def explicit_list_to_html(s)

    match = s.match(/<([ou]l)>([\*#])/m)

    if match then

      type, symbol = match.captures
      symbol = ('\\' + symbol) if symbol == '*'

      a3 = s.split(/(?=<#{type}>)/).map do |x|

        if x =~ /<ol>/ then
          "<%s>%s</%s>" % \
              [type, x[/<#{type}>[#{symbol}]\s*(.*)<\/#{type}>/m,1]\
               .split(/\n#{symbol}\s*/).map {|y| "<li>%s</li>" % y}.join, type]
        else
          x
        end
      end

    else
      s
    end
    
  end
  
  def hyperlinkify(s)
    
   s.gsub(/\[([^\[]+)\]\(([^\)]+\)\)?\))/) do |x|
      "<a href='#{$2.chop}'>#{$1}</a>"
    end

  end
    
  
  def mtlite_utils(s)
    
    # convert square brackets to unicode check boxes
    # replaces a [] with a unicode checkbox, 
    #                         and [x] with a unicode checked checkbox
    s2 = s.gsub(/\s\[ {0,1}\]\s/,' &#9744; ').gsub(/\s\[x\]\s/,' &#9745; ')
    
    # create domain labels for hyperlinks
    #
    s3 =  s2.gsub(/(?:^\[|\s\[)[^\]]+\]\((https?:\/\/[^\s]+)/) do |x|

      next x if @ignore_domainlabel and x[/#{@ignore_domainlabel}/]

      a = x[/https?:\/\/([^\/]+)/,1].split(/\./)
      r = a.length >= 3 ? a[1..-1] :  a
      "%s <span class='domain'>[%s]</span>" % [x, r.join('.')]
    end

    # add strikethru to completed items
    # e.g. -milk cow- becomes <del>milk cow</del>
    s3.gsub(/\s-[^-]+-?[^-]+-[\s\]]/) do |x|
      x.sub(/-([&\w]+.*\w+)-/,'<del>\1</del>')
    end    

  end
  
  def nomarkdown(s)
    s.gsub(/\b'\b/,"{::nomarkdown}'{:/}")
  end
  
  def qrcodetag(s)
    
    s.gsub(/\B!q\[\]\((https?:\/\/[^\)]+)\)/) do 
      
      svg = RQRCode::QRCode.new($1).as_svg     
      svg.slice!(/.*(?=<svg)/m)
      
      svg
    end

  end  
  
  def ordered_list_to_html(s)
    list_to_html s, '#'
  end
  
  def dx_render_table(dx, raw_select)
  
    fields, markdown, heading, inner = nil, true, true, true
    
    if raw_select then

      raw_fields = raw_select[/select:\s*["']([^"']+)/,1]
      
      fields = raw_fields.split(/\s*,\s*/) if raw_fields
      inner = false if raw_select[/\bmarkdown:\s*false\b/]
      heading = false if raw_select[/\bheading:\s*false\b/]

    end
    

    dx.to_table(markdown: true, fields: fields, innermarkdown: inner, 
                heading: heading)
  end  
  
  def dx_render_table2(dx, raw_select)
    
      markdown, heading = true, true
      
      if raw_select then
        raw_fields = raw_select[/select:\s*["']([^"']+)/,1]
        fields = raw_fields.split(/\s*,\s*/) if raw_fields
        markdown = false if raw_select[/\bmarkdown:\s*false\b/]
        heading = false if raw_select[/\bheading:\s*false\b/]
      end
      
      print_row = -> (row, widths) do
        '| ' + row.map\
            .with_index {|y,i| y.to_s.ljust(widths[i])}.join(' | ') + " |\n"
      end

      print_thline = -> (row, widths) do
        '|:' + row.map\
            .with_index {|y,i| y.to_s.ljust(widths[i])}.join('|:') + "|\n"
      end

      print_rows = -> (rows, widths) do
        rows.map {|x| print_row.call(x,widths)}.join
      end



      flat_records = raw_select ? dx.to_a(select: fields) : dx.to_a
      
      keys = flat_records.map(&:keys).first
      raw_vals = flat_records.map(&:values)
      
      # create Markdown hyperlinks for any URLs
      
      vals = raw_vals.map do |row|

        row.map do |col|

          found_match = col.match(/^https?:\/\/([^\/]+)(.*)/)

          r = if found_match then

            domain, path = found_match.captures

            a = domain.split('.')
            a.shift if a.length > 2
            url_title = (a.join('.') + path)[0..39] + '...'

            "[%s](%s)" % [url_title, col]
            
          else
            
            if markdown then 
              "{::nomarkdown}" + 
                  RDiscount.new(col).to_html.strip.gsub("\n",'') + "{:/}"
            else

              col
              
            end
            
          end
          
          r
        end
      end      

      widths = ([keys] + vals).transpose.map{|x| x.max_by(&:length).length}
      
            
      th = heading  ? print_row.call(keys, widths) : ''
      th_line = print_thline.call widths.map {|x| '-' * (x+1)}, widths        
      tb = print_rows.call(vals, widths)      
        
      table = th + th_line + tb
      
    end
  
  def unordered_list_to_html(s)
    list_to_html s, '\*'
  end

  def parse__data__(s)

    puts 'inside parse__data__'.info if @debug
    
    a = s.split(/^__DATA__$/,2)

    data = a[-1]
    
    links, locals = data.split(/(?=<)/, 2)
    
    links.strip.split("\n").each do |line|
      
      puts ('line:'  + line.inspect).debug if @debug
      next if line.nil?
      
      id, url = line.split(/:\s+/,2)
      puts 'id: ' + id.inspect if @debug
      puts 'url: ' + url.inspect if @debug
      
      obj, _ = RXFHelper.read(url, auto: true)
      define_singleton_method(id.to_sym) { @data_source[id] }
      @data_source[id] = obj 
      
    end
    
    puts 'before locals' if @debug
    
    locals ||= ''
    
    locals.split(/(?=<\?)/).each do |x|

      puts ('__data__ x: ' + x.inspect).debug if @debug
      
      s2 = x.strip
      next if s2.empty?
      
      id = s2.lines.first[/id=["']([^"']+)/,1]
      
      @data_source[id] = case s2 
      when /^<\?dynarex /
        
        dx = Dynarex.new
        dx.import s2
        dx
        
      when /^<\?mindmap(?:viz)? /
        puts 's2: ' + s2.inspect if @debug
        Mindmapviz.new s2
        
      when /^<\?flowchart(?:viz)? /
        
        Flowchartviz.new s2        
        
      when /^<\?sectionx /
        
        sx = SectionX.new
        sx.import s2
        define_singleton_method(id.to_sym) { @data_source[id] }
        sx
        
      when /^<\?kvx /
        
        kvx = Kvx.new s2

        define_singleton_method(id.to_sym) { @data_source[id] }
        kvx        
        
      end    
    end
    
    a[0..-2].join
    
  end

  def table_to_html(s)
    
    # create any tables
    s.gsub!(/^\[[^|]+\|[^\n]+\n\|[^\]]+\]/) do |x|

      rows = x.split(/\n/).map{|x| x.split(/[\[\|\]]/).reject(&:empty?)}

      xml = RexleBuilder.new
      a = xml.table do
        rows.each do |cols|
          xml.tr do
            cols.each do |col|
              xml.td escape(col)
            end
          end
        end
      end

      r = Rexle.new(a).xml pretty: true, declaration: false
      r
    end
    return s
  end

  def underline(s)

    s.gsub(/_[^_\(\)\n]+_\b/) do |x| 
      "<span class='underline'>%s</span>" % x[1..-2]
    end

  end
  
  def highlight(s)

    s.gsub(/\^[\w ]+\^/) {|x| "<mark>%s</mark>" % x[1..-2] }

  end

  def script_out(s)
    s.gsub(/({!)[^}]+\}/) {|x| eval(x[/(?<={!)[^}]+/]) }
  end
  
  def smartlink(s)
        
    s.split(/(?= \?)/).inject('') do |r, substring|

      r << substring.gsub(/\B\?([^\n]+) +(https?:\/\/.[^\?]+\?)(?=\B)/) do |x|
        
        content, link = $1, ($2).chop
        
        if (link)[/\)$/] then
          "<a href='%s'>%s</a>" % [link, content]
        else
          "[%s](%s)" % [content, link]
        end
      end
      
    end    

  end  
  
  def slashpre(s)
    s.gsub(/^\/\/([^\/]+)^\/\//) do |x|
      "<pre>#{($1).lines.map{|y| y.sub(/^ +/,'')}.join}</pre>"
    end
    
  end
  
  # makes HTML sections out of string blocks which start with an 
  # equals sign and end with an equals sign
  def section(s)

    a = s.lines

    a2 = a.inject([[]]) do |r,x|
      
      match = x.match(/^={1}(?:#)?([\w-]+)?$/)

      if match then

        if r.last.length > 0 and r.last.first[/<section/] then

          list = r.pop
          puts ('section | list: ' + list.inspect).debug if @debug

          r << ["%s%s</section>" % 
                 [list[0], \
                  Martile.new(list[1..-1].join, \
                      ignore_domainlabel: @ignore_domainlabel).to_html
                 ]
               ]
          puts ('section | r: ' + r.inspect) if @debug
          r << []
        else

          raw_id = match.captures.first
          id = raw_id ? (" id='%s'" % raw_id) : ''          
          r << ["<section#{id} markdown='1'>"]
        end
        
      else

        r.last << x
      end

      r
    end

    a2.join
  end
  
  def svgtag(s)
    
    s.gsub(/\B!s\[\]\((#\w+|https?:\/\/[^\)]+)\)/) do 
      
      source = ($1)  
      
      svg = if source =~ /^http/ then
      
        RXFHelper.read(source).first        
        
      else
        
        @data_source[source[/\w+/]].to_svg
        
      end     
      
      svg.slice!(/.*(?=<svg)/m)
      svg
    end

  end
  
  
  def videotag(s)
    
    s.gsub(/\B!v\[\]\((https?:\/\/[^\)]+)\)(\{[^\}]+\})?/) do |match|

      files = ($1).split
      attr = ($2)

      h = attr ? attr.scan(/(\w+):\s+(\w+)/).to_h : {}
      attributes = h.any? ? (' ' + 
                             h.map {|k,v| "%s='%s'" % [k,v]}.join(' ')) : ''

      h2 = {
        /\.og[gv]$/ => 'ogg', /\.mp4$/ => 'mp4', /\.mov$/ => 'mov', 
        /\.webm$/ => 'webm' 
      }

      sources = files.map do |file|

        type = h2.detect{|k,v| file[k] }.last
        "  <source src='%s' type='video/%s'/>" % [file, type]
      end

      "<video controls='controls'%s>\n%s\n</video>" % [attributes, sources.join("\n")]
    end    
  
  end
  
  def list_item_to_hyperlink(s)
        
    s.gsub(/\B(\* +)([^\n]+)\s+(https?:\/\/.*)/,'\1[\2](\3)')

  end    
end
