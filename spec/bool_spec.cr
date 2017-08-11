require "./spec_helper"

private class BoolMapping
  Toka.mapping({
    foo: Bool,
    bar: Bool?,
    default: {
      type: Bool,
      default: true,
    },
    nilable_default: {
      type: Bool?,
      default: true,
    }
  })
end

describe "Type test" do
  it "defines getters" do
    methods = {{ BoolMapping.methods.map(&.name.stringify).sort }}
    methods.should eq %w[ bar bar? default default? foo foo? initialize nilable_default nilable_default? positional_options ]
  end

  describe "long name" do
    it "requires --foo" do
      expect_raises(Toka::MissingOptionError) do
        BoolMapping.new(%w[ --bar ])
      end
    end

    it "accepts --foo" do
      subject = BoolMapping.new(%w[ --foo ])
      subject.foo.should eq true
      subject.bar.should eq nil
    end

    it "accepts --no-foo" do
      subject = BoolMapping.new(%w[ --no-foo ])
      subject.foo.should eq false
      subject.bar.should eq nil
    end

    it "accepts --foo --bar" do
      subject = BoolMapping.new(%w[ --foo --bar ])
      subject.foo.should eq true
      subject.bar.should eq true
    end

    it "accepts --foo --no-bar" do
      subject = BoolMapping.new(%w[ --foo --no-bar ])
      subject.foo.should eq true
      subject.bar.should eq false
    end
  end

  describe "short name" do
    it "accepts -f" do
      subject = BoolMapping.new(%w[ -f ])
      subject.foo.should eq true
      subject.bar.should eq nil
    end

    it "accepts -F" do
      subject = BoolMapping.new(%w[ -F ])
      subject.foo.should eq false
      subject.bar.should eq nil
    end

    it "accepts -F -b" do
      subject = BoolMapping.new(%w[ -F -b ])
      subject.foo.should eq false
      subject.bar.should eq true
    end

    it "accepts -F -B" do
      subject = BoolMapping.new(%w[ -F -B ])
      subject.foo.should eq false
      subject.bar.should eq false
    end
  end

  describe "explicit value setting" do
    it "accepts --foo=x for truthy" do
      %w[ true t yes y ].each do |x|
        subject = BoolMapping.new([ "--foo=#{x}" ])
        subject.foo.should eq true
      end
    end

    it "accepts --foo=x for falsy" do
      %w[ false f no n ].each do |x|
        subject = BoolMapping.new([ "--foo=#{x}" ])
        subject.foo.should eq false
      end
    end

    it "accepts --bar=x for truthy" do
      %w[ true t yes y ].each do |x|
        subject = BoolMapping.new([ "-f", "--bar=#{x}" ])
        subject.bar.should eq true
      end
    end

    it "accepts --bar=x for falsy" do
      %w[ false f no n ].each do |x|
        subject = BoolMapping.new([ "-f", "--bar=#{x}" ])
        subject.bar.should eq false
      end
    end
  end

  describe "default behaviour" do
    it "uses the default value" do
      subject = BoolMapping.new(%w[ --foo ])
      subject.default.should eq true
    end

    it "accepts --default" do
      subject = BoolMapping.new(%w[ --foo --default ])
      subject.default.should eq true
    end

    it "accepts --no-default" do
      subject = BoolMapping.new(%w[ --foo --no-default ])
      subject.default.should eq false
    end

    it "accepts --default=yes" do
      subject = BoolMapping.new(%w[ --foo --default=yes ])
      subject.default.should eq true
    end

    it "accepts --default=no" do
      subject = BoolMapping.new(%w[ --foo --default=no ])
      subject.default.should eq false
    end
  end

  describe "nilable-default behaviour" do
    it "uses the default value" do
      subject = BoolMapping.new(%w[ --foo ])
      subject.nilable_default.should eq true
    end

    it "accepts --nilable-default" do
      subject = BoolMapping.new(%w[ --foo --nilable-default ])
      subject.nilable_default.should eq true
    end

    it "accepts --no-nilable-default" do
      subject = BoolMapping.new(%w[ --foo --no-nilable-default ])
      subject.nilable_default.should eq false
    end

    it "accepts --nilable-default=yes" do
      subject = BoolMapping.new(%w[ --foo --nilable-default=yes ])
      subject.nilable_default.should eq true
    end

    it "accepts --nilable-default=no" do
      subject = BoolMapping.new(%w[ --foo --nilable-default=no ])
      subject.nilable_default.should eq false
    end
  end
end
