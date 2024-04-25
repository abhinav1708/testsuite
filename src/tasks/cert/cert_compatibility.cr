# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s kubectl"
task "cert_compatibility", ["cert_compatibility_title", "helm_chart_valid", "helm_chart_published", "helm_deploy", "increase_decrease_capacity", "rollback"] do |_, args|
# task "cert_compatibility", ["cert_compatibility_title", "helm_chart_valid", "helm_chart_published", "helm_deploy", "cni_compatible", "increase_decrease_capacity", "rollback"] do |_, args|
  # stdout_score("compatibility", "Compatibility, Installability, and Upgradeability")
  stdout_score(["compatibility", "cert"], "Compatibility, Installability, and Upgradeability")
  case "#{ARGV.join(" ")}" 
  when /cert_compatibility/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end

end

task "cert_compatibility_title" do |_, args|
  puts "Compatibility, Installability & Upgradability Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))
end
