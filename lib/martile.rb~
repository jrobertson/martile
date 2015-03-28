#!/usr/bin/env ruby

# file: martile.rb

#require 'rexle-builder'
#require 'rexle'
require 'dynarex'
require 'rdiscount'


# bug fix: 28-Mar-2015: Fixes a bug introduced on the 20-Mar-2015 relating to 
#                       Markdown lists not neing converted to HTML 
#  see http://www.jamesrobertson.eu/bugtracker/2015/mar/28/markdown-lists-are-not-converted-to-html.html
# feature:  21-Mar-2015: URLS are now given labels e.g.
#          [news](http://news.bbc.co.uk)<span class='domain'>[bbc.co.uk]</span>
# bug fix:  20-Mar-2015: HTML and XML elements should not be filtered out of 
#                                                          the section() method
# feature:               Added the unicode checkbox feature from the Mtlite gem
# bug fix:  14-Mar-2015: A section can now be
#                                        written without an error occurring
# bug fix:  11-Mar-2015: Escapes angle brackets within a code block *before* 
#                        the string is passed to Rexle
# bug fix:               A new line character is now added after the creation 
#                        of the code block tags
# bug fix:  01-Mar-2015: code_block_to_html() now only searches strings which 
#                        are outside of angle brackets
# bug fix:  10-Dec-2014: Generation of pre tags using // can now only happen 
#                        when the // appears at the beginning of the line
# feature:  30-Oct-2014: A section can now be between a set of equal signs at 
#                        the beginning of the line 
#                        e.g. 
#                        =
#                            inside a section
#                        =
# bug fix:  07-Oct-2014: Smartlink tested for new cases
# feature:  27-Sep-2014: 1. A smartlink can now be used 
#                                               e.g. ?link http://someurl?
#                        2. pre tags can now be created from 2 pairs of slash 
#                           tags, before and after the pre tag content e.g.
#                            //
#                            testing
#                            //
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

  def initialize(raw_s, ignore_domainlabel: nil)
    
    @ignore_domainlabel = ignore_domainlabel
    
    s = slashpre raw_s
    #puts 's : ' + s.inspect
    s2 = code_block_to_html(s.strip + "\n")

    #puts 's2 : ' + s2.inspect
    s3 = apply_filter(s2, %w(ol ul)) {|x| explicit_list_to_html x }
    #puts 's3 : ' + s3.inspect
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
    #s10 = apply_filter(s9) {|x| section x }
    s10 = apply_filter(s9) {|x| mtlite_utils x }        
    s11 = section s10
    


    #puts 's8 : ' + s8.inspect

    @to_html = s11
  end

  private

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
  
  def dynarex_to_table(s)

    s.gsub(/-\[((https?:\/\/)?[\w\/\.\-]+)\]/) do |match|
      
      dynarex = Dynarex.new($1)
      dynarex.to_h.map(&:values)
      '[' + dynarex.to_h.map{|x| escape(x.values.join('|')) + "\n"}.join('|').chomp + ']'
    end
  end
  
  def escape(s)
    s.gsub('<','&lt;').gsub('>','&gt;')
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
          block.call(x.xml pretty: false)
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
  
  def mtlite_utils(s)
    
    # convert square brackets to unicode check boxes
    # replaces a [] with a unicode checkbox, 
    #                         and [x] with a unicode checked checkbox
    s2 = s.gsub(/\s\[\s*\]\s/,' &#9744;').gsub(/\s\[x\]\s/,' &#9745;')    
 
    s2.gsub(/(?:^\[|\s\[)[^\]]+\]\((https?:\/\/[^\s]+)/) do |x|

      next x if @ignore_domainlabel and x[/#{@ignore_domainlabel}/]
      
      s2 = x[/https?:\/\/([^\/]+)/,1].split(/\./)
      r = s2.length >= 3 ? s2[1..-1] :  s2
      "%s<span class='domain'>[%s]</span>" % [x, r.join('.')]
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
    
    s.gsub(/\B\?([^\n]+) +(https?:\/\/.*\?)(?=\B)/) do
      "[%s](%s)" % [$1, ($2).chop]
    end

  end  
  
  def slashpre(s)
    s.gsub(/^\/\/([^\/]+)^\/\//) do |x|
      "<pre>#{($1).lines.map{|y| y.sub(/^ +/,'')}.join}</pre>"
    end
    
  end
  
  def section(s)

    a = s.lines

    a2 = a.inject([[]]) do |r,x|

      match = x.match(/^=[^=]#?(\w+)?/)

      if match then

        if r.last.length > 0 and r.last.first[/<section/] then

          list = r.pop
          r << ["%s%s</section>" % 
                [list[0], RDiscount.new(list[1..-1].join).to_html]]
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
  
end