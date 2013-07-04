#!/usr/bin/env ruby

module SPSS2Latex
  def self.convert(tables)
    tables.split(/^\s*$/).map { |t| convert_one(t) }.join("\n\n\n\n")
  end
  
  private
    def self.convert_one(table)
      t = table
      t.gsub!(/^[^|].*?$\n/, "")
      t.gsub!(/^$\n/, "")
      t.gsub!(/(^\||\|$)/, "")

      @hlines = t.scan(/^[\|\-|\s]+$/)
      cols = @hlines.map{ |hline| hline.count("|") }.max

      # parse hline with all columns to determine table structure
      l = @hlines.select { |l| l.count("|") == cols }[0]
      @col_widths = l.split("|").map{ |c| c.length }
      @ncols = @col_widths.length

      t = t.split("\n")[0..-2]

      rows = []
      t.each_with_index do |r, i|
        if i % 2 == 0
          rows[(i / 2).to_i] = { :s => r.split("|") }
        else
          rows[(i / 2).to_i][:c] = r.split("|")
        end
      end

      @nrows = rows.length

      out = []
      rows.each_with_index do |row, i|
        r = [] # next row to be added
        nc = 0
        ci = 0
        begin
          cspan = get_column_span(nc, row[:s][ci].length)
          rspan = get_row_span(ci, i)
          r.push(:rspan => rspan, :cspan => cspan, :content => row[:c][ci])
          r[-1][:empty] = true if row[:s][ci].split("")[0] != "-"
          nc += cspan
          ci += 1
        end while nc != @ncols
        out.push(r)
      end

      lines = []
      out.each_with_index do |row, ri|
        l = "  "
        row.each_with_index do |col, ci|
          l += " & " unless ci == 0
          unless col[:empty]
            c = col[:content].strip
            c = "\\multicolumn{#{col[:cspan]}}{c}{#{c}}" if col[:cspan] > 1
            #c = "\\multirow{#{col[:rspan]}}{*}{#{c}}" if col[:rspan] > 1
            l += c
          end
        end
        lines.push l
      end

      out = "\\begin{tabular}{ #{"l " * @ncols}}\n"
      out += lines.join(" \\\\\n")
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
end

# if ARGV.length < 1
#   abort "Usage: spss2latex.rb <exported-tables.txt>"
# end
# 
# tables = File.read(ARGV[0]).split(/^\s*$/)
# puts tables.map { |t| SPSS2Latex.convert(t) }.join("\n\n\n\n")
