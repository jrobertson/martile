#!/usr/bin/env ruby

# file: martile.rb

#require 'rexle-builder'
#require 'rexle'
require 'dynarex'
require 'rdiscount'


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
    s10 = section s9
    
    s11 = apply_filter(s10) {|x| mtlite_utils x }    

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
    s2 = s.gsub(/\[\s*\]/,'&#9744;').gsub(/\[x\]/,'&#9745;')    
 
    s2.gsub(/(?:^\[|\s\[)[^\]]+\]\((https?:\/\/[^\s]+)/) do |x|

      next x if @ignore_domainlabel and x[/#{@ignore_domainlabel}/]
      
      s2 = x[/https?:\/\/([^\/]+)/,1].split(/\./)
      r = s2.length >= 3 ? s2[1..-1] :  s2
      "%s <span class='domain'>[%s]</span>" % [x, r.join('.')]
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