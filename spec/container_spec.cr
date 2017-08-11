require "./spec_helper"

private class ListTest
  Toka.mapping({
    list: Array(String),
    bools: Array(Bool),
    nilable: Array(String)?,
    default: {
      type: Array(Int32),
      default: [ 6, 7, 8 ],
    },
    nilable_default: {
      type: Array(Int32)?,
      default: [ 3, 4, 5 ],
    },
  })
end

private class HashTest
  Toka.mapping({
    map: Hash(String, String),
    bools: Hash(Int32, Bool),
    nilable: Hash(String, String)?,
    default: {
      type: Hash(String, Int32),
      default: { "foo" => 1 },
    },
    nilable_default: {
      type: Hash(String, Int32)?,
      default: { "bar" => 2 },
    },
  })
end

describe "container support" do
  context "on Array" do
    describe "without input" do
      it "defaults to empty containers" do
        subject = ListTest.new(%w[ ])
        subject.list.empty?.should eq true
        subject.bools.empty?.should eq true
        subject.nilable.try(&.empty?).should eq true
      end

      it "uses the given defaults" do
        subject = ListTest.new(%w[ ])
        subject.default.should eq [ 6, 7, 8 ]
        subject.nilable_default.should eq [ 3, 4, 5 ]
      end
    end

    describe "adding values" do
      it "works for String" do
        subject = ListTest.new(%w[ --list=one --list two -lthree -l four ])
        subject.list.should eq [ "one", "two", "three", "four" ]
      end

      it "works for Int32" do
        subject = ListTest.new(%w[ --default=1 --default 2 -d3 -d 4 ])
        subject.default.should eq [ 1, 2, 3, 4 ]
      end

      it "works for Bool" do
        subject = ListTest.new(%w[ --bools=yes --bools=no])
        subject.bools.should eq [ true, false ]
      end
    end
  end

  context "on Hash" do
    describe "without input" do
      it "defaults to empty containers" do
        subject = HashTest.new(%w[ ])
        subject.map.empty?.should eq true
        subject.bools.empty?.should eq true
        subject.nilable.try(&.empty?).should eq true
      end

      it "uses the given defaults" do
        subject = HashTest.new(%w[ ])
        subject.default.should eq({ "foo" => 1 })
        subject.nilable_default.should eq({ "bar" => 2 })
      end
    end

    describe "adding values" do
      it "works for String" do
        subject = HashTest.new(%w[ --map=one=two --map three=four -mfive=six -m seven=eight ])
        subject.map.should eq({ "one" => "two", "three" => "four", "five" => "six", "seven" => "eight" })
      end

      it "works for Int32" do
        subject = HashTest.new(%w[ --default=one=1 --default two=2 -dthree=3 -d four=4 ])
        subject.default.should eq({ "one" => 1, "two" => 2, "three" => 3, "four" => 4 })
      end

      it "works for Bool" do
        subject = HashTest.new(%w[ --bools=1=yes --bools 2=no ])
        subject.bools.should eq({ 1 => true, 2 => false })
      end
    end
  end
end
