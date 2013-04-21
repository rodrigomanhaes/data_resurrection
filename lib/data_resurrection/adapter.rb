# coding: utf-8

module DataResurrection
  module Adapter
  end
end

Dir.glob(File.dirname(__FILE__) + '/adapter/*.rb') {|f| require f }