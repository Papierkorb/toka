require "colorize"

module Toka
  # Renderer for a `OptionDescriptor`, to be shown on a terminal.
  #
  # By default, the user of your program can access this using the defualt
  # arguments "--help" and "-h".  You can disable this if you want, see
  # `Toka.mapping`.
  #
  # ## Manual invocation
  #
  # To manually render the help page, simply use `#to_s`:
  #
  # ```
  # help = Toka::HelpPageRenderer.new(YourOptionClass)
  # puts help.to_s
  # ```
  class HelpPageRenderer
    OPTION_INDENT = "  "
    BASE_INDENT =  OPTION_INDENT.size + 4 + 2
    MAX_ALIGN = 20

    @descr : OptionDescriptor
    @align : Int32

    def initialize(options, @colors : Bool = true)
      options = options.toka_options unless options.is_a? OptionDescriptor
      @descr = options

      longest = @descr.options.max_of do |opt|
        name_len = opt.long_names.first?.try(&.size) || 0
        name_len + opt.value_name.size + 1
      end

      @align = { MAX_ALIGN, longest }.min
    end

    def to_s(io)
      io.puts @descr.banner
      render_options(io)
      io.puts @descr.footer if @descr.footer
    end

    def render_options(io)
      categories = @descr.options.group_by(&.category)
      first = true

      categories.each do |name, options|
        io.puts unless first
        io.puts name.colorize.mode(:bold).toggle(@colors) if name
        render_option_list(io, options)

        first = false
      end
    end

    def render_option_list(io, options)
      options.each do |option|
        render_option(io, option)
      end
    end

    def render_option(io, option)
      long = option.long_names.first?
      short = option.short_names.first?
      indent_size = BASE_INDENT

      io.print OPTION_INDENT
      if short
        io.print "#{"-".colorize(:green).toggle(@colors)}#{short.colorize.mode(:bright).toggle(@colors)}"
        io.print option.value_name if option.has_value? && !long
      else
        io.print "  "
      end

      if short && long
        io.print ", "
      else
        io.print "  "
      end

      if long
        base_size = long.size
        long = long.colorize.mode(:bright).toggle(@colors).to_s

        if option.has_value?
          base_size += 1 + option.value_name.size
          long += "=#{option.value_name.colorize.mode(:dim).toggle(@colors)}"
        end

        align_size = { (@align - base_size + 2), 2 }.max
        indent_size += base_size + align_size
        align = " " * align_size
        io.print "#{"--".colorize(:green).toggle(@colors)}#{long}#{align}"
      else
        io.print " " * (@align + 2)
      end

      if description = option.description
        description = description.gsub('\n', "\n" + " " * indent_size) # Reindent multiline descriptions
        io.print description
      end

      io.puts # Force new-line
    end
  end
end
