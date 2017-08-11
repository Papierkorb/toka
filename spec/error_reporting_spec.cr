require "./spec_helper"

private class UnknownMapping
  Toka.mapping({
    foo: Int32?,
    bar: Bool?
  })
end

private class MissingMapping
  Toka.mapping({
    foo: Int32,
    bar: Bool?
  })
end

private class HashMissingMapping
  Toka.mapping({
    filler: Bool?,
    foo: Hash(String, Int32)
  })
end

private module BrokenConverter
  def self.read(x)
    nil.as(Int32?)
  end
end

private class ConverterMapping
  Toka.mapping({
    foo: {
      type: Int32,
      converter: BrokenConverter,
    }
  })
end

private class VerifierMapping
  Toka.mapping({
    foo: {
      type: String?,
      verifier: ->(x : String){ false },
    },
    bar: {
      type: String?,
      verifier: ->(x : String){ "Nope" },
    },
  })
end

private macro catch(type, mapping, words)
  %err = nil

  begin
    {{ mapping }}.new({{ words }})
  rescue error : {{ type }}
    %err = error
    %err.arguments.should eq({{ words }})
  end

  %err.not_nil!
end

describe "error reporting" do
  describe Toka::UnknownOptionError do
    it "is raised when an unknown option is encountered" do
      err = catch(Toka::UnknownOptionError, UnknownMapping, %w[ --foo=4 bar --unknown ])
      err.position.should eq 2
      err.name.should eq "--unknown"
    end

    it "is raised when an unknown short-option is encountered" do
      err = catch(Toka::UnknownOptionError, UnknownMapping, %w[ --foo=4 -bu ])
      err.position.should eq 1
      err.name.should eq "u"
    end
  end

  describe Toka::MissingOptionError do
    it "is raised when a required option is missing" do
      err = catch(Toka::MissingOptionError, MissingMapping, %w[ --bar ])
      err.option.should eq MissingMapping.toka_options[0]
    end
  end

  describe Toka::MissingValueError do
    it "is raised when no value has been supplied" do
      err = catch(Toka::MissingValueError, MissingMapping, %w[ --bar --foo ])
      err.option.should eq MissingMapping.toka_options[0]
      err.position.should eq 1
    end
  end

  describe Toka::HashValueMissingError do
    it "is raised when no hash value has been supplied" do
      err = catch(Toka::HashValueMissingError, HashMissingMapping, %w[ --foo thing ])
      err.option.should eq HashMissingMapping.toka_options[1]
      err.position.should eq 1
    end
  end

  describe Toka::ConversionError do
    it "is raised when the converter returns nil" do
      err = catch(Toka::ConversionError, ConverterMapping, %w[ --foo 123 ])
      err.option.should eq ConverterMapping.toka_options[0]
      err.position.should eq 1
    end
  end

  describe Toka::VerificationError do
    it "is raised when the verifier returns false" do
      err = catch(Toka::VerificationError, VerifierMapping, %w[ --foo bar ])
      err.option.should eq VerifierMapping.toka_options[0]
      err.position.should eq 1
      err.verifier_message.should eq nil
    end

    it "is raised when the verifier returns a String" do
      err = catch(Toka::VerificationError, VerifierMapping, %w[ --bar=foo ])
      err.option.should eq VerifierMapping.toka_options[1]
      err.position.should eq 0
      err.verifier_message.should eq "Nope"
      err.message.should match(/: Nope$/)
    end
  end
end
