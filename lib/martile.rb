#!/usr/bin/env ruby

# file: martile.rb

require 'rexle-builder'
require 'rexle'
require 'dynarex'
require 'rdiscount'


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
    s2 = code_block_to_html(s)
    
    s3 = ordered_list_to_html(s2)
    
    s4 = unordered_list_to_html(s3)  
    
    s5 = dynarex_to_table(s4)      
    
    s6 = table_to_html(s5)      
    
    @to_html = s6
  end

  private

  def code_block_to_html(s)

    b =[]

    while s =~ /^ {4}/ do
      
      a = s.lines.to_a
      r = a.take_while{|x| x[/^( {4}|\n)/]}
      
      if r.join.strip.length > 0 then        
        code_block = "<pre><code>%s</code></pre>" % \
          a.shift(r.length).map{|x| x.sub(/^ {4}/,'')}.join\
          .gsub('<','&lt;').gsub('>','&gt;')
        b << code_block
        s = a.join
        i = r.length        
      else        
        i = (s =~ /^ {4}/)        
      end

      b << s.slice!(0,i)
      
    end
    
    b.join("\n") + s    

  end
  
  def dynarex_to_table(s)

    s.gsub(/-\[((https?:\/\/)?[\w\/\.\-]+)\]/) do |match|
      
      dynarex = Dynarex.new($1)
      dynarex.to_h.map(&:values)
      '[' + dynarex.to_h.map{|x| x.values.join('|') + "\n"}
        .join('|').chomp + ']'
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

      Rexle.new(a).xml pretty: true, declaration: false

    end
    return s
  end

end
