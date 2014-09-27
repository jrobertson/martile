#!/usr/bin/env ruby

# file: martile.rb

require 'rexle-builder'
require 'rexle'
require 'dynarex'
require 'rdiscount'


# feature:  27-Sep-2014: A smartlink can now be used e.g. ?link http://someurl?
# feature:  24-Sep-2014: A kind of markdown list can now be created inside 
#                        of <ol> or <ul> tags
# bug fix:  16-Apr-2014: Words containing an underscore should no longer be 
#                        transformed to an underline tag
# bug fix:  03-Apr-2014: XML or HTML elements should now be filtered out 
#                        of any transformations.
# feature:  31-Mar-2014: Added an _underline_ feature.
# bug fix:  01-Mar-2014: A Dynarex_to_table statement between 2 HTML blocks 
#                        is now handled properly.
# bug fix:  01-Mar-2014: Multiple pre tags within a string can now be handled
# feature:  12-Oct-2013: escaped the non-code content of <pre> blocks
# feature:  04-Oct-2013: angle brackets within <pre><code> blocks are 
#                        escaped automatically
# feature:  03-Oct-2013: HTML tags now handled
# bug fix:  25-Sep-2013: removed the new line statement from the join command.
#                        headings etc. should no longer be split with a new line
# feature:  12-Aug-2013: unordered_list supported
# feature:  31-Mar-2013: markdown inside a martile ordered list
#                          is now converted to HTML
# bug fix:  02-Nov-2012: within dynarex_to_table URLs containing a 
#                        dash now work
# bug fix:  20-Sep-2012: in ordered_list_to_html it now cuts off from 
#                        parsing headings
# bug fix:  04-Aug-2012; replaced \s with a space in regex patterns
# modified: 28-Mar-2012; Added dynarex_to_table
# modified: 28-Aug-2011; Added escaping of HTML within a code block

class Martile

  attr_reader :to_html

  def initialize(s)

    raw_s2 = apply_filter(s.strip) {|x| code_block_to_html x }

    # ensure all angle brackets within <pre><code> is escaped
    s2 = raw_s2.split(/(?=<pre><code>)/m).map { |y|
      y.sub(/<pre><code>(.*)<\/code><\/pre>/m) do |x|
      s3 = ($1)
      "<pre><code>%s</code></pre>" % s3.gsub(/</,'&lt;').gsub(/>/,'&gt;')
      end
    }.join

    # escape the content of <pre> tags which doesn't contain the code tag
    s2.gsub(/<(pre)>[^(?:<\/\1>)]+<\/\1>/m) do |x|
      s = x[5..-7]
      if s[/^<code>/] then
        x
      else
        "<pre>%s</pre>" % s.gsub(/</,'&lt;').gsub(/>/,'&gt;')
      end
    end

    #puts 's2 : ' + s2.inspect
    s3 = apply_filter(s2, %w(ol ul)) {|x| explicit_list_to_html x }
    s4 = apply_filter(s3) {|x| ordered_list_to_html x }
    #puts 's4 : ' + s4.inspect

    s5 = apply_filter(s4) {|x| unordered_list_to_html x }
    #puts 's5 : ' + s5.inspect

    s6 = apply_filter(s5) {|x| dynarex_to_table x }
    #puts 's6 :' + s6.inspect

    s7 = apply_filter(s6) {|x| table_to_html x }
    #puts 's7 : ' + s7.inspect

    s8 = apply_filter(s7) {|x| underline x }
    s9 = apply_filter(s8) {|x| smartlink x }

    #puts 's8 : ' + s8.inspect

    @to_html = s9
  end

  private

  def code_block_to_html(s)

    b =[]

    while s =~ /^ {4}/ do

      a = s.lines.to_a
      r = a.take_while{|x| x[/^( {4}|\n)/]}
      
      if r.join.strip.length > 0 then
        raw_code = a.shift(r.length).map{|x| x.sub(/^ {4}/,'')}.join

        code_block = "<pre><code>%s</code></pre>" % raw_code

        b << code_block
        s = a.join
        i = r.length        
      else        
        i = (s =~ /^ {4}/)        
      end

      b << s.slice!(0,i)
      
    end
    
    b.join + s    

  end
  
  def dynarex_to_table(s)

    s.gsub(/-\[((https?:\/\/)?[\w\/\.\-]+)\]/) do |match|
      
      dynarex = Dynarex.new($1)
      dynarex.to_h.map(&:values)
      '[' + dynarex.to_h.map{|x| x.values.join('|').gsub('<','&lt;')\
                            .gsub('>','&gt;') + "\n"}.join('|').chomp + ']'
    end
  end

  def list_to_html(s,symbol='#')

    return s unless s[/\[#{symbol}[^\]]+\]/]
    tag = {'#' => 'ol', '\*' => 'ul'}[symbol]

    s.split(/(?=\[#{symbol}|^#{symbol*2})/).map do |x|
      
      s2, remainder = [x[/\[#{symbol}.*#{symbol}[^\]]+\]/m], ($').to_s] if x.strip.length > 0
      
      if s2 then

        raw_list = s2[1..-2].split(/^#{symbol}/).reject(&:empty?).map(&:strip)
        list = "<#{tag}>%s</#{tag}>" % raw_list.map {|x| \
                    "<li>%s</li>" % RDiscount.new(x).to_html[/<p>(.*)<\/p>/,1]}.join
        list + remainder.to_s
        
      else
        
        x
        
      end
      
    end.join

  end  

  def apply_filter(s, names=[], &block)

    Rexle.new("<root>#{s}</root>").root.map do |x|  

      if x.is_a?(String) then
        block.call(x)
      else
        
        if names.grep  x.name then
          block.call(x.xml)
        else
          x
        end   
        
      end      
    end.join
  end
  
  def explicit_list_to_html(s)

    match = s.match(/<([ou]l)>([\*#])/m)

    if match then

      type, symbol = match.captures
      symbol = ('\\' + symbol) if symbol == '*'

      a3 = s.split(/(?=<#{type}>)/).map do |x|
       # puts 'x' + x.inspect
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
  
  def ordered_list_to_html(s)
    list_to_html s, '#'
  end
  
  def unordered_list_to_html(s)
    list_to_html s, '\*'
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
              xml.td col.gsub('<','&lt;').gsub('>','&gt;')
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
    s.gsub(/\B\?([^\n]+) +(https?:\/\/[^\b]+)\?\B/,'[\1](\2)')
  end
  
end
