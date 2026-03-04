# frozen_string_literal: true

module Mjml
  class MjmlRbParser
    class ParseError < StandardError; end

    attr_reader :template_path, :input

    # Create new parser
    #
    # @param template_path [String] The path to the .mjml file
    # @param input [String] The string to transform in html
    def initialize(template_path, input)
      @template_path = template_path
      @input         = input
      @with_cache    = Cache.new(template_path)
    end

    # Render mjml template
    #
    # @return [String]
    def render
      @with_cache.cache do
        result = run
        html = result.fetch(:html).to_s
        errors = Array(result[:errors])

        if errors.any?
          formatted_errors = format_errors(errors)

          if Mjml.validation_level.to_s == 'strict' || html.empty?
            raise ParseError, formatted_errors
          end

          Mjml.logger.warn(formatted_errors)
        end

        html
      rescue NameError
        Mjml.logger.fatal('MJML-RB is not installed. Please add `gem "mjml-rb"` to your Gemfile.')
        raise
      rescue StandardError
        raise if Mjml.raise_render_exception

        ''
      end
    end

    private

    def run
      raise NameError unless defined?(::MjmlRb) && ::MjmlRb.respond_to?(:to_html)

      normalize_result(::MjmlRb.to_html(input, build_options))
    end

    def normalize_result(raw_result)
      return { html: raw_result, errors: [] } if raw_result.is_a?(String)

      hash_result = raw_result.respond_to?(:to_h) ? raw_result.to_h : raw_result
      return { html: raw_result.to_s, errors: [] } unless hash_result.is_a?(Hash)

      {
        html: hash_result[:html] || hash_result['html'],
        errors: hash_result[:errors] || hash_result['errors']
      }
    end

    def build_options
      {
        beautify: Mjml.beautify,
        minify: Mjml.minify,
        validation_level: Mjml.validation_level
      }
    end

    def format_errors(errors)
      errors.map do |error|
        next error.to_s unless error.is_a?(Hash)

        error[:formatted_message] || error['formatted_message'] || error[:message] || error['message'] || error.to_s
      end.join("\n")
    end
  end
end
