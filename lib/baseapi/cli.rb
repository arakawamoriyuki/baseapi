# coding: utf-8

require 'thor'
require 'fileutils'

module Baseapi
  class CLI < Thor

    desc "Base API setup", "create jbuilder view."
    def setup(*controllers)
      controllers.push 'application'
      controllers.push 'base_api'
      controllers.uniq!
      controllers.each do |controller|
        dir = [
          "app/views/#{controller}"
        ]
        dir.each do |path|
          if !Dir.exists?(path)
            Dir.mkdir(path)
          end
        end

        files = [
          'error.json.jbuilder',
          'model.json.jbuilder',
          'models.json.jbuilder',
        ]

        files.each do |file|
          src = File.expand_path("../app/views/base_api/#{file}", __FILE__)
          FileUtils.cp(src, "app/views/#{controller}/#{file}")
        end
      end
    end
  end
end
