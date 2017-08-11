module Toka

  # This file contains internal helper methods and macros for `Toka.mapping`.
  # None of these are expected to be used outside of it!

  # Internal helper.  Do not use.
  def self._fetch_value(name, option, value, strings, index)
    if value.nil?
      value = strings[index + 1]?

      if value.nil? || value.starts_with?('-')
        raise ::Toka::MissingValueError.new("Missing value for option #{name.inspect}", strings, index, option)
      end

      index += 1
    end

    { value, index }
  end

  # Internal helper.  Do not use.
  def self._convert_value(raw, converter, name, error_args)
    value = converter.read(raw)

    if value.nil?
      raise ::Toka::ConversionError.new("Failed to convert value #{raw.inspect} for option #{name.inspect}", *error_args)
    else
      value
    end
  end

  # Internal helper.  Do not use.
  macro _maybe_fetch_value(name, type, bool_default)
    {% if type.resolve == Bool %}
      value = {{ bool_default }} if value.nil?
    {% else %}
      value, index = ::Toka._fetch_value({{ name.stringify }}, option, value, strings, index)
    {% end %}
  end

  # Internal helper.  Do not use.
  macro _convert_and_verify(raw, verifier, converter, name, strings, index, option)
    %value = ::Toka._convert_value({{ raw }}, {{ converter }}, {{ name }}, { {{ [ strings, index, option ].splat }} })

    {% if verifier %}
      response = ({{ verifier }}).call(%value)
      if response == false
        raise ::Toka::VerificationError.new("Verification failed for value #{{{ raw }}.inspect} for option #{{{name}}.inspect}", {{ strings }}, {{ index }}, {{ option }}, nil)
      elsif response.is_a?(String)
        raise ::Toka::VerificationError.new("Verification failed for value #{{{ raw }}.inspect} for option #{{{name}}.inspect}: #{response}", {{ strings }}, {{ index }}, {{ option }}, response)
      end
    {% end %}

    %value
  end

  # Internal helper.  Do not use.
  macro _read_value(target, name, config, bool_default)
    option = @@toka_options.options[{{ config[:index] }}]

    {% if config[:mode] == :single %}
      ::Toka._maybe_fetch_value({{ name }}, {{ config[:value_type] }}, {{ bool_default }})
      {{ target }} = ::Toka._convert_and_verify(value, {{ config[:value_verifier] }}, {{ config[:value_converter].id }}, "{{ name }}", strings, index, option)
    {% elsif config[:mode] == :sequential %}
      ::Toka._maybe_fetch_value({{ name }}, {{ config[:value_type] }}, {{ bool_default }})
      {{ target }} << ::Toka._convert_and_verify(value, {{ config[:value_verifier] }}, {{ config[:value_converter].id }}, "{{ name }}", strings, index, option)
    {% elsif config[:mode] == :associative %}
      value, index = ::Toka._fetch_value({{ name.stringify }}, option, value, strings, index)

      unless value.includes?('=')
        raise ::Toka::HashValueMissingError.new("Missing value in pair for option {{ name }}", strings, index, option)
      end

      key, val = value.split('=', 2)
      %key_{name} = ::Toka._convert_and_verify(key, {{ config[:key_verifier] }}, {{ config[:key_converter].id }}, "{{ name }}", strings, index, option)
      %val_{name} = ::Toka._convert_and_verify(val, {{ config[:value_verifier] }}, {{ config[:value_converter].id }}, "{{ name }}", strings, index, option)
      {{ target }}[%key_{name}] = %val_{name}
    {% end %}
  end
end
