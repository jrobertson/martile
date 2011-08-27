#!/usr/bin/env ruby

# file: martile.rb

require 'rexle-builder'
require 'rexle'

class Martile

  attr_reader :to_html

  def initialize(s)
    s2 = code_block_to_html(s)
    s3 = ordered_list_to_html(s2)
    s4 = table_to_html(s3)      
    @to_html = s4
  end

  private

  def code_block_to_html(s)

    s.split(/(?=\n\n\s{4})/).map do |x|
      raw_code_block = x[/.*\s{4}[^\n]+/m]

      if raw_code_block then
        code_block = "<pre><code>%s</code></pre>" % \
          raw_code_block.lines.map{|x| x[4..-1]}[1..-1].join
        code_block + ($').to_s
      else
        x
      end
    end.join("\n")

  end

  def ordered_list_to_html(s)

    s.split(/(?=\[#)/).map do |x|
      s2, remainder = [x[/\[#.*#[^\]]+\]/m], ($').to_s] if x.strip.length > 0
      if s2 then

        raw_list = s2[1..-2].split(/^#/).reject(&:empty?).map(&:strip)
        list = "<ol>%s</ol>" % raw_list.map {|x| "<li>%s</li>" % x}.join
        list + remainder.to_s
      else
        x
      end
    end.join

  end

  def table_to_html(s)
    # create any tables
    s.gsub!(/\[[^|]+\|[^\n]+\n\|[^\]]+\]/) do |x|

      rows = x.split(/\n/).map{|x| x.split(/[\[\|\]]/).reject(&:empty?)}

      xml = RexleBuilder.new
      a = xml.table do
        rows.each do |cols|
          xml.tr do
            cols.each do |col|
              xml.td col
            end
          end
        end
      end

      Rexle.new(a).xml pretty: true, declaration: false

    end
    return s
  end

end
