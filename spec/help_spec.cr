require "./spec_helper"

private class TestMapping
  Toka.mapping({
    name: {
      type: String,
      value_name: "NAME",
      description: "This is a long\nmultiline description!"
    },
    long_option_name: {
      type: String,
      value_name: "LONG_TOO",
      description: "This options name is quite long indeed\nAnd the description is even worse",
      category: "Long options"
    },
    normal: {
      type: String,
      description: "A normal one for once",
      category: "Long options"
    },
    toggle: Bool,
    aliased: {
      type: String,
      long: [ "one", "two" ],
      short: [ "1", "2" ],
      description: "I have a few custom aliases",
    },
  }, {
    banner: "This is my banner",
    footer: "This is my footer",
    help: true,
    colors: false,
  })
end

describe "--help feature" do
  it "stores all data" do
    TestMapping.toka_options.should eq Toka::OptionDescriptor.new(
      "This is my banner",
      "This is my footer",
      [
        Toka::Option.new("name", [ "name" ], [ 'n' ], "NAME", "This is a long\nmultiline description!", nil, true),
        Toka::Option.new("long_option_name", [ "long-option-name" ], [ 'l' ], "LONG_TOO", "This options name is quite long indeed\nAnd the description is even worse", "Long options", true),
        Toka::Option.new("normal", [ "normal" ], [ 'o' ], "VALUE", "A normal one for once", "Long options", true),
        Toka::Option.new("toggle", [ "toggle", "no-toggle" ], [ 't', 'T' ], "VALUE", nil, nil, false),
        Toka::Option.new("aliased", [ "one", "two" ], [ '1', '2' ], "VALUE", "I have a few custom aliases", nil, true),
        Toka::Option.new("help", [ "help" ], [ 'h' ], "", "Shows this help", nil, false),
      ]
    )
  end

  it "renders a pretty help page" do
    renderer = Toka::HelpPageRenderer.new(TestMapping, colors: false)
    renderer.to_s.should eq <<-EOF
This is my banner
  -n, --name=NAME             This is a long
                              multiline description!
  -t, --toggle                
  -1, --one=VALUE             I have a few custom aliases
  -h, --help                  Shows this help

Long options
  -l, --long-option-name=LONG_TOO  This options name is quite long indeed
                                   And the description is even worse
  -o, --normal=VALUE          A normal one for once
This is my footer

EOF
  end
end
