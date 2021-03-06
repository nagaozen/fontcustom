require 'json'
require 'thor/group'

module Fontcustom
  class Generator < Thor::Group
    include Thor::Actions

    desc 'Generates webfonts from given directory of vectors.'

    argument :input, :type => :string
    argument :output, :type => :string, :optional => true

    def self.source_root
      File.dirname(__FILE__)
    end

    def verify_input_dir
      if ! File.directory?(input)
        raise Thor::Error, "#{input} doesn't exist or isn't a directory."
      elsif Dir[File.join(input, '*.{svg,eps}')].empty?
        raise Thor::Error, "#{input} doesn't contain any vectors (*.svg or *.eps files)."
      end
    end

    def verify_or_create_output_dir
      @output = output.nil? ? File.join(File.dirname(input), 'fontcustom') : output
      empty_directory(@output) unless File.directory?(@output)
    end

    def cleanup_output_dir
      originals = Dir[File.join(@output, 'fontcustom*.{css,woff,ttf,eot,svg}')]
      originals.each do |file|
        remove_file file
      end
    end

    def generate
      gem_file_path = File.expand_path(File.join(File.dirname(__FILE__)))
      @font = %x| fontforge -script #{gem_file_path}/scripts/generate.py #{input} #{@output} 2>&1 /dev/null |
      @font = JSON.parse(@font.split("\n").last)
    end

    def show_paths
      path = @font['file']
      ['woff','ttf','eot','svg'].each do |type|
        say_status(:create, path + '.' + type)
      end
    end

    def create_stylesheet
      @font['file'] = File.basename(@font['file'])
      template('templates/fontcustom.css', File.join(@output, 'fontcustom.css'))
    end
  end
end
