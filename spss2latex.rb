#!/usr/bin/env ruby

module SPSS2Latex
  def self.convert(tables)
    tables.split(/^\s*$/).map { |t| convert_one(t) }.join("\n\n\n\n")
  end
  
  private
    def self.convert_one(table)
      t = table
      t.gsub!(/^[^|].*?$\n/, "")
      t.gsub!(/^\s$\n/, "")
      t.gsub!(/(^\s*\||\|\s*$)/, "")

      @hlines = t.scan(/^[\|\-|\s]+$/)
      cols = @hlines.map{ |hline| hline.count("|") }.max

      # parse hline with all columns to determine table structure
      l = @hlines.select { |l| l.count("|") == cols }[0]
      @col_widths = l.split("|").map{ |c| c.length }
      @ncols = @col_widths.length

      t.gsub!(/(^[\s\|\-]*$\n?)/, "")
      t = t.split("\n")

      rows = []
      t.each_with_index do |r, i|
        #if i % 2 == 1
          rows[i] = r.split("|")
          #end
      end

      @nrows = rows.length

      out = []
      rows.each_with_index do |row, i|
        r = [] # next row to be added
        nc = 0
        ci = 0
        begin
          cspan = get_column_span(nc, row[ci].length)
          rspan = get_row_span(ci, i)
          r.push(:rspan => rspan, :cspan => cspan, :content => row[ci])
          r[ci][:empty] = row[ci].strip.empty?
          nc += cspan
          ci += 1
        end while nc != @ncols
        out.push(r)
      end
      
      lines = []
      col_spans = Hash.new
      out.each_with_index do |row, ri|
        l = []
        row.each_with_index do |col, ci|
          unless col[:empty]
            c = col[:content].strip
            c = "\\multicolumn{#{col[:cspan]}}{c}{#{c}}" if col[:cspan] > 1
            #c = "\\multirow{#{col[:rspan]}}{*}{#{c}}" if col[:rspan] > 1
            col_spans[[ci, ri]] = col[:cspan]
            l.push c
            (col[:cspan] - 1).times { l.push nil }
          else
            l.push ""
          end
        end
        lines.push l
      end
      
      # adjust cell widths to align &s
      @max_lens = [0] * @ncols
      10.times do |span_limit|
        lines.each_with_index do |l, li|
          l.each_with_index do |c, ci|
            span = col_spans[[ci, li]] || 1
            if span <= span_limit && col_width_total(ci, span) < (c || "").length
              @max_lens[ci] += c.length - col_width_total(ci, span)
            end
          end
        end
      end
      lines = lines.each_with_index.map do |line, li|
        line.each_with_index.map do |c, ci|
          if c.nil?
            nil
          else
            span = col_spans[[ci, li]] || 1
            c.ljust(col_width_total(ci, span))
          end
        end.compact
      end

      out = "\\begin{tabular}{ #{"l " * @ncols}}\n  "
      #out += lines.join(" \\\\\n")
      out += lines.map { |l| l.join(" & ") }.join(" \\\\\n  ")
      out += "\n\\end{tabular}"
      return out
    end
  
    def self.get_column_span(column_index, column_width)
      cws = @col_widths[column_index..-1]
      n = 0
      while column_width > n - 1
        column_width -= cws[n]
        n += 1
      end
      n
    end

    def self.get_row_span(column_index, row_index)
      return 1 if row_index == @nrows - 1

      if column_index == 0
        ind = 0
      else
        ind = @col_widths[0..column_index-1].inject{ |sum, x| sum + x } + column_index
      end
      return @hlines[row_index + 1..-1].map { |l| l.split("")[ind] }.join("").match(/^(\s*)/).to_s.length + 1
    end
    
    def self.col_width_total(column_index, span)
      @max_lens[column_index..column_index + span - 1].inject{ |sum, x| sum + x } + 3*(span - 1)
    end
end

if ARGV.length < 1
  abort "Usage: spss2latex.rb <exported-tables.txt>"
end
puts SPSS2Latex.convert(File.read(ARGV[0]))
