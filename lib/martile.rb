#!/usr/bin/env ruby

# file: martile.rb

#require 'rexle-builder'
#require 'rexle'
require 'dynarex'
require 'rdiscount'
require 'kvx'


# bug fix:  11-Jun-2016  pre tags are now filtered out properly
# feature:  22-May-2016  Introduced the __DATA__ section which appears at 
#                        the end of the document to reference 1 or more raw 
#                        Dynarex documents
# improvement: 9-Mar-2016 Method dynarex_to_markdown now uses the !d[]() 
#                        syntax instead of -[]
# bug fix:  29-Feb-2016  Arbitrary URLs will no longer automatically 
#                        be hyperlinked
# bug fix:  05-Dec-2015  PRE tags are now correctly filtered out using the 
#                        apply_filter() method.
#                        the ignore_domainlabel keword is now supplied to the 
#                        Martile.new statement within the section() method
# bug fix:  04-Dec-2015  apply_filter() now masks over <pre> tags rather than
#                        splitting them and passing them to the block
# bug fix:  03-Dec-2015  A smartlink which ends with a closing parenthesis is 
#                          now output to a regular anchor tag
#                        It should now identify when using a section equals sign
#                        to terminate a section block
#                        The content of a section block can now be processed 
#                           using the Martile object recursively
# bug fix:  22-Oct-2015  The method apply_filter() is now used 
#                                                 with the section() method
# feature:  10-Oct-2015  A hyperlink can now be create from a 
#                        list item containing a URL
# bug fix:  06-Oct-2015  Can now handle multiple smart links on the same line
# bug fix:  17-Aug-2015  dx_render_table() was missing a couple of parameters
# feature:  09-Aug-2015  kvx_to_dl() can convert a kind of 
#                        markdown URL to a DL HTML list
# feature:  02-Aug-2015  dynarex_to_table() is now know as dynarex_to_markdown()
#                        A markdown list will be rendered from a Dynarex 
#                        document if there is only a single field column
# improvement: 
#           16-Jul-2015  to_s is now equivalent to_html; to_s is 
#                        more readable when it's just text which is returned
# feature:  06-Jul-2015  dynarex_to_markdown(): 
#                        1. A URL within a  col is now hyperlinked
#                        2. Select fields can now be displayd
# feature:  02-Jul-2015  Apply_filter() now filters out pre and code tags
#                        The shorthand !i[]() can now render an iframe tag 
#                        e.g. !i[](http://somefile.url/sometext.txt)                        
# feature:  19-Jun-2015  Now uses github flavoured markdown to style the table
#           01-Jun-2015  re-applied yesterday's feature which I 
#                        removed shortly afterwards
# feature:  31-May-2015: Transforms a kind-of markdown URL to an audio tag 
#    e.g. !a[](http://someurl) transforms to ). Transforms a kind-of 
#   markdown URL to an video tag e.g. !v[](http://someurl) transforms to )
# bug fix:               The inner Martile call within a Section now 
#  ignores domain labels to avoid duplication of URL scanning.
# feature:  29-Mar-2015: Borrowed the strikethru feature from Mtlite


class Martile

  attr_reader :to_s, :data_source

  def initialize(raw_s, ignore_domainlabel: nil)
    
    @data_source = {}
    
    @ignore_domainlabel = ignore_domainlabel

    
    s0 = raw_s =~ /^__DATA__$/ ? parse__data__(raw_s) : raw_s
    #puts 's0: ' + s0.inspect
    s1 = apply_filter(s0) {|x| slashpre x }
    #puts 's1 : ' + s1.inspect
    s2 = apply_filter(s1) {|x| code_block_to_html(x.strip + "\n") }

    #puts 's2 : ' + s2.inspect
    #s3 = apply_filter(s2, %w(ol ul)) {|x| explicit_list_to_html x }
    #puts 's3 : ' + s3.inspect
    s4 = apply_filter(s2) {|x| ordered_list_to_html x }
    #puts 's4 : ' + s4.inspect

    s5 = apply_filter(s4) {|x| unordered_list_to_html x }
    #puts 's5 : ' + s5.inspect

    s6 = apply_filter(s5) {|x| dynarex_to_markdown x }
    #puts 's6 :' + s6.inspect

    s7 = apply_filter(s6) {|x| table_to_html x }
    #puts 's7 : ' + s7.inspect

    s8 = apply_filter(s7) {|x| underline x}
    #puts 's8: ' + s8.inspect
    s9 = apply_filter(s8) {|x| section x }
    #puts 's9: ' + s9.inspect
    
    s10 = apply_filter(s9) {|x| smartlink x }

    #puts 's10: ' + s10.inspect

    #s11 = section s9
    #puts 's11 : ' + s11.inspect
    s12 = apply_filter(s10) {|x| audiotag x }
    #puts 's12 : ' + s12.inspect
    s13 = apply_filter(s12) {|x| videotag x }
    #puts 's13 : ' + s13.inspect
    s14 = apply_filter(s13) {|x| iframetag x }
    #puts 's14 : ' + s14.inspect
    s15 = apply_filter(s14) {|x| kvx_to_dl x }
    #puts 's15 : ' + s15.inspect
    s16 = apply_filter(s15) {|x| list_item_to_hyperlink x }
    #puts 's16 : ' + s16.inspect
    s17 = apply_filter(s16) {|x| mtlite_utils x }
    
    #puts 's17 : ' + s17.inspect
    
    @to_s = s17
  end
  
  def to_html()
    @to_s
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
        
        b =[]

        while s2 =~ /^ {4}/ do

          a = s2.lines.to_a
          r = a.take_while{|x| x[/^( {4}|\n)/]}
          
          if r.join.strip.length > 0 then
            raw_code = a.shift(r.length).map{|x| x.sub(/^ {4}/,'')}.join

            code_block = "<pre><code>%s</code></pre>\n" % escape(raw_code)

            b << code_block
            s2 = a.join
            i = r.length        
          else        
            i = (s =~ /^ {4}/)        
          end

          b << s2.slice!(0,i)
          
        end
        
        b.join + s2
      else
        s2
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
  
  def escape(s)
    s.gsub('<','&lt;').gsub('>','&gt;')
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
  
  def mtlite_utils(s)
    
    # convert square brackets to unicode check boxes
    # replaces a [] with a unicode checkbox, 
    #                         and [x] with a unicode checked checkbox
    s2 = s.gsub(/\s\[\s*\]\s/,' &#9744; ').gsub(/\s\[x\]\s/,' &#9745; ')
    
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
  
  def ordered_list_to_html(s)
    list_to_html s, '#'
  end
  
  def dx_render_table(dx, raw_select)
    
      if raw_select then
        raw_fields = raw_select[/select:\s*["']([^"']+)/,1]
        fields = raw_fields.split(/\s*,\s*/)        
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

          found_match = col.match(/https?:\/\/([^\/]+)(.*)/)

          r = if found_match then

            domain, path = found_match.captures

            a = domain.split('.')
            a.shift if a.length > 2
            url_title = (a.join('.') + path)[0..39] + '...'

            "[%s](%s)" % [url_title, col]
          else
            col
          end
          
          r
        end
      end      

      widths = ([keys] + vals).transpose.map{|x| x.max_by(&:length).length}
      th = '|' + keys.join('|') + "|\n"
      th = print_row.call(keys, widths)
      th_line = print_thline.call widths.map {|x| '-' * (x+1)}, widths

      tb = print_rows.call(vals, widths)
      table = th + th_line + tb
    end
  
  def unordered_list_to_html(s)
    list_to_html s, '\*'
  end

  def parse__data__(s)

    a = s.split(/^__DATA__$/,2)

    data = a[-1]

    data.split(/(?=<\?)/).each do |x|
    
      s2 = x.strip
      next if s2.empty?
      
      id = s2.lines.first[/id=["']([^"']+)/,1]
      dx = Dynarex.new
      dx.import s2

      @data_source[id] = dx    
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
      
      match = x.match(/^={1}(?:#)?(\w+)?$/)

      if match then

        if r.last.length > 0 and r.last.first[/<section/] then

          list = r.pop

          r << ["%s%s</section>" % 
                 [list[0], \
                  RDiscount.new(Martile.new(list[1..-1].join, \
                      ignore_domainlabel: @ignore_domainlabel).to_html).to_html
                 ]
               ]
          r << []
        else

          raw_id = match.captures.first
          id = raw_id ? (" id='%s'" % raw_id) : ''          
          r << ["<section#{id}>"]
        end
        
      else

        r.last << x
      end

      r
    end

    a2.join
  end
  
  def videotag(s)
    
    s.gsub(/\B!v\[\]\((https?:\/\/[^\)]+)\)\B/) do |x|
      
      files = ($1).split

      h = {
        /\.og[gv]$/ => 'ogg', /\.mp4$/ => 'mp4', /\.mov$/ => 'mov', 
        /\.webm$/ => 'webm' 
      }

      sources = files.map do |file|
        type = h.detect{|k,v| file[k] }.last
        "  <source src='%s' type='video/%s'/>" % [file, type]
      end

      "<video controls='controls'>\n%s\n</video>" % [sources.join("\n")]
    end    
  
  end
  
  def list_item_to_hyperlink(s)
        
    s.gsub(/\B(\* +)([^\n]+)\s+(https?:\/\/.*)/,'\1[\2](\3)')

  end    
end