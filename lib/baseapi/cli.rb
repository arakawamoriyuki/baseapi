# coding: utf-8

require 'thor'
require 'fileutils'

module Baseapi
  class CLI < Thor

    desc "Base API setup", "create BaseApiController and jbuilder view."
    def setup
      dir = [
        'app/views/base_api'
      ]
      dir.each do |path|
        if !Dir.exists?(path)
          Dir.mkdir(path)
        end
      end

      files = {
        'base_api_controller.rb'  => 'controllers',
        'error.json.jbuilder'     => 'views/base_api',
        'model.json.jbuilder'     => 'views/base_api',
        'models.json.jbuilder'    => 'views/base_api',
      }

      files.each do |file, path|
        src = File.expand_path("../app/#{path}/#{file}", __FILE__)
        FileUtils.cp(src, "app/#{path}/#{file}")
      end
    end
  end
end
