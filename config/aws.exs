import Config

config :passwordless, :aws,
  regions: %{
    "af-south-1" => %{"description" => "Africa (Cape Town)"},
    "ap-northeast-1" => %{"description" => "Asia Pacific (Tokyo)"},
    "ap-northeast-2" => %{"description" => "Asia Pacific (Seoul)"},
    "ap-east-1" => %{"description" => "Asia Pacific (Hong Kong)"},
    "ap-south-1" => %{"description" => "Asia Pacific (Mumbai)"},
    "ap-southeast-1" => %{"description" => "Asia Pacific (Singapore)"},
    "ap-southeast-2" => %{"description" => "Asia Pacific (Sydney)"},
    "ap-southeast-3" => %{"description" => "Asia Pacific (Jakarta)"},
    "ca-central-1" => %{"description" => "Canada (Central)"},
    "eu-central-1" => %{"description" => "EU (Frankfurt)"},
    "eu-west-1" => %{"description" => "EU (Ireland)"},
    "eu-west-2" => %{"description" => "EU (London)"},
    "eu-west-3" => %{"description" => "EU (Paris)"},
    "eu-north-1" => %{"description" => "EU (Stockholm)"},
    "eu-south-1" => %{"description" => "EU (Milan)"},
    "me-south-1" => %{"description" => "Middle East (Bahrain)"},
    "sa-east-1" => %{"description" => "South America (Sao Paulo)"},
    "us-east-1" => %{"description" => "US East (N. Virginia)"},
    "us-east-2" => %{"description" => "US East (Ohio)"},
    "us-west-1" => %{"description" => "US West (N. California)"},
    "us-west-2" => %{"description" => "US West (Oregon)"}
  }
