$:.unshift(File.dirname(__FILE__) + '/lib')
require "rubygems"
require "bundler/setup"
require "spec"
require 'statemachine'
require 'scxml-parser'

$IS_TEST = true