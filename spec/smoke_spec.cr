require "./spec_helper"

private class SimpleMapping
  Toka.mapping({
    string: String,
    optional: Int32?,
    a_bool: Bool,
    nilable: { # Equivalent to `nilable: String?`
      type: String,
      nilable: true,
    }
  })
end

describe "Smokee test" do # Smoke test
  describe "with simple mapping" do
    it "defines getters" do
      methods = {{ SimpleMapping.methods.map(&.name.stringify).sort }}
      methods.should eq %w[ a_bool a_bool? initialize nilable optional positional_options string ]
    end

    it "accepts input" do
      subject = SimpleMapping.new(%w[ --string=foo --optional=4 --a-bool ])
      subject.string.should eq "foo"
      subject.optional.should eq 4
      subject.a_bool.should eq true
      subject.nilable.should eq nil
    end
  end
end
