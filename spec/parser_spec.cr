require "./spec_helper"

private class ParserTest
  Toka.mapping({
    foo:     Bool?,
    bar:     Bool?,
    string:  String?,
    another: String?,
    lib:     Bool?,
    def:     Bool?,
  })
end

describe "parser behaviour" do
  it "accepts empty input" do
    subject = ParserTest.new(%w[])
    subject.foo.should eq nil
    subject.bar.should eq nil
    subject.string.should eq nil
    subject.another.should eq nil
  end

  describe "long names" do
    it "accepts long names" do
      subject = ParserTest.new(%w[--foo --bar])
      subject.foo.should eq true
      subject.bar.should eq true
      subject.string.should eq nil
    end

    it "accepts single long name with value in next word" do
      subject = ParserTest.new(%w[--string foo])
      subject.string.should eq "foo"
    end

    it "accepts many long names with value in next word" do
      subject = ParserTest.new(%w[--string foo --another bar])
      subject.string.should eq "foo"
      subject.another.should eq "bar"
    end

    it "accepts single long name with =VALUE" do
      subject = ParserTest.new(%w[--string=foo])
      subject.string.should eq "foo"
    end

    it "accepts many long names with =VALUE" do
      subject = ParserTest.new(%w[--string=foo --another=bar])
      subject.string.should eq "foo"
      subject.another.should eq "bar"
    end

    it "accepts --string foo --another=bar" do
      subject = ParserTest.new(%w[--string foo --another=bar])
      subject.string.should eq "foo"
      subject.another.should eq "bar"
    end

    it "accepts --string=foo --another bar" do
      subject = ParserTest.new(%w[--string=foo --another bar])
      subject.string.should eq "foo"
      subject.another.should eq "bar"
    end
  end

  describe "short names" do
    it "accepts short names without a value" do
      subject = ParserTest.new(%w[-f -B])
      subject.foo.should eq true
      subject.bar.should eq false
    end

    it "accepts many short names without a value in the same word" do
      subject = ParserTest.new(%w[-fB])
      subject.foo.should eq true
      subject.bar.should eq false
    end

    it "accepts short name with a value in the next word" do
      subject = ParserTest.new(%w[-s foo])
      subject.string.should eq "foo"
    end

    it "accepts many short names with a value in the next word" do
      subject = ParserTest.new(%w[-s foo -a bar])
      subject.string.should eq "foo"
      subject.another.should eq "bar"
    end

    it "accepts many short names with a value in the same word" do
      subject = ParserTest.new(%w[-sfoo -abar])
      subject.string.should eq "foo"
      subject.another.should eq "bar"
    end

    it "accepts many short names with and without value in the same word" do
      subject = ParserTest.new(%w[-fBsfoo])
      subject.foo.should eq true
      subject.bar.should eq false
      subject.string.should eq "foo"

      subject = ParserTest.new(%w[-Fbsfoo])
      subject.foo.should eq false
      subject.bar.should eq true
      subject.string.should eq "foo"
    end

    it "accepts many short names with and without value in the same word and value in next" do
      subject = ParserTest.new(%w[-fBs foo])
      subject.foo.should eq true
      subject.bar.should eq false
      subject.string.should eq "foo"

      subject = ParserTest.new(%w[-Fbs foo])
      subject.foo.should eq false
      subject.bar.should eq true
      subject.string.should eq "foo"
    end
  end

  describe "positional options" do
    it "stores bare-words" do
      subject = ParserTest.new(%w[one -fB two])
      subject.foo.should eq true
      subject.bar.should eq false
      subject.positional_options.should eq %w[one two]
    end

    it "stores escaped options without leading back-slash" do
      subject = ParserTest.new(%w[one \-fB two \--foo])
      subject.foo.should eq nil
      subject.bar.should eq nil
      subject.positional_options.should eq %w[one -fB two --foo]
    end

    it "supports parser cancellation" do
      subject = ParserTest.new(%w[-f -- -B two --no-foo])
      subject.foo.should eq true
      subject.bar.should eq nil
      subject.positional_options.should eq %w[-B two --no-foo]
    end

    it "supports all at once" do
      subject = ParserTest.new(%w[one -f \-B -- two --no-foo])
      subject.foo.should eq true
      subject.bar.should eq nil
      subject.positional_options.should eq %w[one -B two --no-foo]
    end
  end

  describe "with equal-sign in value" do
    it "works in long-names with =VALUE notation" do
      subject = ParserTest.new(%w[--string=foo=bar])
      subject.string.should eq "foo=bar"
    end

    it "works in long-names with value in next word" do
      subject = ParserTest.new(%w[--string foo=bar])
      subject.string.should eq "foo=bar"
    end

    it "works in short-names with value in same word" do
      subject = ParserTest.new(%w[-sfoo=bar])
      subject.string.should eq "foo=bar"
    end

    it "works in short-names with value in next word" do
      subject = ParserTest.new(%w[-s foo=bar])
      subject.string.should eq "foo=bar"
    end

    it "accepts reserved words" do
      subject = ParserTest.new(%w[--lib --no-def])
      subject.lib.should eq true
      subject.def.should eq false
    end
  end
end
