require 'shellwords'

module SourceControl
  class Subversion

    # This class is responsible for parsing the output of `svn propget -R
    # svn:externals`. See the #parse method.
    #
    # TODO This whole class should probably be rewritten so it is more generic.
    # I took improper shortcuts such as skipping SVN external entries with
    # revisions; this should correctly parse such entries and it might be more
    # proper to have SourceControl::Subversion#up_to_date? decide what entries
    # to skip.
    class Subversion::PropgetParser
      def initialize(subversion)
        @subversion = subversion
      end

      def parse(lines)
        lines = lines.lines if lines.is_a?(String) && lines.respond_to?(:lines)
        
        directories = {}
        current_dir = nil
        lines.each do |line|
          split = line.split(" - ")
          if split.length > 1
            current_dir = split[0]
            line = split[1]
          end

          url, directory = parse_line(line, current_dir)
          if url
            directories["#{current_dir}/#{directory}"] = url
          end
        end
        directories
      end

      # Given +property_target+ (directory on which the svn:externals property
      # was set) and +line+ (a line in the property), this returns an Array
      # where the first element is the URL and the second is the directory.
      #
      # If +line+ is blank, a comment, or contains more than 2 elements (which
      # may indicate an external pinned to a revision), then this returns
      # +nil+.
      def parse_line(line, property_target)
        return nil if line.start_with?('#')

        # Using shellsplit so paths with spaces and escaped characters are
        # handled correctly (although paths with newline characters won't work)
        args = Shellwords.shellsplit(line)

        # If args doesn't have exactly 2 elements, then it probably means the
        # line is using -r. We'll ignore these cases for now because
        # SourceControl::Subversion#up_to_date? does not need to check these
        # cases.
        return nil unless args.length == 2

        begin
          uri = URI.parse(args[1])
          is_old_svn_external = !uri.scheme.nil?
        rescue URI::InvalidURIError
          is_old_svn_external = false
        end

        if is_old_svn_external
          # format for Subversion < 1.5
          return args[1], args[0]
        else
          # format for Subversion >= 1.5
          return resolve_external_url(args[0], property_target), args[1]
        end
      end

      # Resolves/canonicalizes the given external +url+.
      def resolve_external_url(url, property_target)
        if url.start_with?('../')
          URI.join(@subversion.repository + '/', property_target + '/', url).to_s
        elsif url.start_with?('^/')
          URI.join(@subversion.info.repository_root + '/', url[2..-1]).to_s
        elsif url.start_with?('//')
          URI.parse(@subversion.repository).scheme + ':' + url
        elsif url.start_with?('/')
          @subversion.repository[
            /\A(#{URI::PATTERN::SCHEME}:\/\/#{URI::PATTERN::SERVER})/, 1
          ] + url
        else
          url
        end
      end
    end
    
  end
end
