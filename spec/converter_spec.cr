require "./spec_helper"

module MyConverter
  def self.read(input) : Int32?
    v = input.to_i * 2
    v if v < 100 # Fail if *input* >= "50"
  end
end

module MyStringConverter
  def self.read(input) : String?
    if input == "fail"
      nil
    else
      input
    end
  end
end

private class TestMapping
  Toka.mapping({
    foo: {
      type: Int32,
      converter: MyConverter,
    },
    bar: {
      type: String, # :value_converter == :converter !
      value_converter: MyStringConverter,
    },
    nilable_bar: {
      type: String?,
      converter: MyStringConverter,
    },
    map: { # Test converter on a Hash
      type: Hash(String, Int32),
      key_converter: MyStringConverter,
      value_converter: MyConverter,
    },
    list: { # List test
      type: Array(Int32),
      converter: MyConverter
    }
  })
end

private class BuiltinMapping
  Toka.mapping({
    u8: UInt8,
    u16: UInt16,
    u32: UInt32,
    u64: UInt64,
    i8: Int8,
    i16: Int16,
    i32: Int32,
    i64: Int64,
    f32: Float32,
    f64: Float64,
    string: String,
    bool: Bool,
    uri: URI,
  })
end

describe "converter behaviour" do
  it "calls the converters" do
    subject = TestMapping.new(%w[ --foo=4 --bar=foo ])
    subject.foo.should eq 8
    subject.bar.should eq "foo"
  end

  describe "built-in converters" do
    it "works" do
      subject = BuiltinMapping.new(%w[ --u8=1 --u16=2 --u32=3 --u64=4 --i8=5 --i16=6 --i32=7 --i64=8 --f32=9 --f64=10 --string=Hello --bool --uri=http://github.com/Papierkorb/ ])
      subject.u8.should eq 1u8
      subject.u16.should eq 2u16
      subject.u32.should eq 3u32
      subject.u64.should eq 4u64
      subject.i8.should eq 5i8
      subject.i16.should eq 6i16
      subject.i32.should eq 7i32
      subject.i64.should eq 8i64
      subject.f32.should eq 9.0f32
      subject.f64.should eq 10.0f64
      subject.bool.should eq true
      subject.string.should eq "Hello"
      subject.uri.should eq URI.parse("http://github.com/Papierkorb/")
    end
  end

  describe "error handling" do
    it "raises for an error in value_converter" do
      expect_raises(Toka::ConversionError) do
        TestMapping.new(%w[ --foo=4 --bar=fail ])
      end
    end

    it "raises for an error in value_converter on nilable field" do
      expect_raises(Toka::ConversionError) do
        TestMapping.new(%w[ --foo=4 --bar=foo --nilable-bar=fail ])
      end
    end

    it "raises for an error in value_converter on sequential field" do
      expect_raises(Toka::ConversionError) do
        TestMapping.new(%w[ --foo=4 --bar=foo --list=10000 ])
      end
    end

    it "raises for an error in value_converter on associative field" do
      expect_raises(Toka::ConversionError) do
        TestMapping.new(%w[ --foo=4 --bar=foo --map yadda=10000 ])
      end
    end

    it "raises for an error in key_converter on associative field" do
      expect_raises(Toka::ConversionError) do
        TestMapping.new(%w[ --foo=4 --bar=foo --map fail=4 ])
      end
    end
  end
end
