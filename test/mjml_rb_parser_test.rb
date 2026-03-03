# frozen_string_literal: true

require 'test_helper'

describe Mjml::MjmlRbParser do
  let(:parser) { Mjml::MjmlRbParser.new('test_template', input) }
  let(:input) { '<mjml><mj-body><mj-text>Hello World</mj-text></mj-body></mjml>' }

  after do
    Object.send(:remove_const, :MJML) if defined?(::MJML)
  end

  describe '#render' do
    it 'renders html when parser returns successful result' do
      stub_mjml_rb(html: '<html>Hello World</html>', errors: [])
      expect(parser.render).must_equal '<html>Hello World</html>'
    end

    it 'raises exception with strict validation and errors' do
      stub_mjml_rb(html: '<html>partial result</html>', errors: [{ formatted_message: 'invalid mjml' }])

      with_settings(validation_level: 'strict', raise_render_exception: true) do
        error = expect { parser.render }.must_raise(Mjml::MjmlRbParser::ParseError)
        expect(error.message).must_equal 'invalid mjml'
      end
    end

    it 'returns html with soft validation and logs warnings' do
      Mjml.logger.stubs(:warn)
      stub_mjml_rb(html: '<html>partial result</html>', errors: [{ formatted_message: 'invalid mjml' }])

      with_settings(validation_level: 'soft') do
        expect(parser.render).must_equal '<html>partial result</html>'
      end
    end

    it 'returns empty string with exception raising disabled' do
      stub_mjml_rb(html: '', errors: [{ formatted_message: 'invalid mjml' }])

      with_settings(validation_level: 'strict', raise_render_exception: false) do
        expect(parser.render).must_equal ''
      end
    end
  end

  private

  def stub_mjml_rb(result)
    Object.send(:remove_const, :MJML) if defined?(::MJML)
    mjml_rb = Module.new
    mjml_rb.define_singleton_method(:to_html) { |_input, _options = {}| result }
    Object.const_set(:MJML, mjml_rb)
  end
end
