# frozen_string_literal: true

%w[local vendor].each do |dir|
  Dir[Rails.root.join("protobuf", dir, "compile/**/*.rb")].sort.each do |file|
    # Supress messages about downcased letters in constants
    Kernel.silence_warnings do
      require_relative(file)
    end
  end
end

Dir[Rails.root.join("pkg/**/*.rb")].sort.each do |file|
  # Supress messages about downcased letters in constants
  Kernel.silence_warnings do
    require_relative(file)
  end
end
