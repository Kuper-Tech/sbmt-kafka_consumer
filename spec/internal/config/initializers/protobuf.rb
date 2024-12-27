# frozen_string_literal: true

%w[local vendor].each do |dir|
  Rails.root.glob("protobuf/#{dir}/compile/**/*.rb").sort.each do |file|
    # Supress messages about downcased letters in constants
    Kernel.silence_warnings do
      require_relative(file)
    end
  end
end

Rails.root.glob("pkg/**/*.rb").sort.each do |file|
  # Supress messages about downcased letters in constants
  Kernel.silence_warnings do
    require_relative(file)
  end
end
