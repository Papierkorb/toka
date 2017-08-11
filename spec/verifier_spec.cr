require "./spec_helper"

private module ComplexVerifier
  def self.call(x)
    x >= 18 || "Failure"
  end
end

private class TestVerifierMapping
  Toka.mapping({
    name: {
      type: String,
      verifier: ->(x : String){ x == "ok" },
    },
    age: {
      type: Int32,
      verifier: ComplexVerifier,
    },
    default: {
      type: Int32,
      verifier: ComplexVerifier,
      default: 5,
    },
    nilable: {
      type: Int32?,
      verifier: ComplexVerifier,
    }
  })
end

private def catch : Toka::VerificationError
  yield
  raise "Nothing was thrown!"
rescue err : Toka::VerificationError
  err
end

describe "verifier test" do
  it "works if all verifiers signal success" do
    subject = TestVerifierMapping.new(%w[ --name=ok --age=20 ])
    subject.name.should eq "ok"
    subject.age.should eq 20
    subject.default.should eq 5
    subject.nilable.should eq nil
  end

  describe "verification failures" do
    it "works with a Proc giving no message" do
      err = catch{ TestVerifierMapping.new(%w[ --name=fail ]) }
      err.verifier_message.should eq nil
      err.message.should match(/name/)
    end

    it "works with a Module giving a message" do
      err = catch{ TestVerifierMapping.new(%w[ --age=10 ]) }
      err.verifier_message.should eq "Failure"
      err.message.should match(/: Failure$/)
      err.message.should match(/age/)
    end

    it "works on a field with a default value" do
      err = catch{ TestVerifierMapping.new(%w[ --default=10 ]) }
      err.verifier_message.should eq "Failure"
      err.message.should match(/: Failure$/)
      err.message.should match(/default/)
    end

    it "works on a nilable field" do
      err = catch{ TestVerifierMapping.new(%w[ --nilable=10 ]) }
      err.verifier_message.should eq "Failure"
      err.message.should match(/: Failure$/)
      err.message.should match(/nilable/)
    end
  end
end
