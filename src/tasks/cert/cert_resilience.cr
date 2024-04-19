# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "../utils/utils.cr"

desc "The CNF test suite checks to see if the CNFs are resilient to failures."
 task "cert_resilience", [
   "cert_resilience_title",
   "pod_network_latency",
   "pod_network_corruption",
   "disk_fill",
   "pod_delete",
   "pod_memory_hog",
   "pod_io_stress",
   "pod_network_duplication",
   "liveness",
   "readiness"
  ] do |t, args|
#  task "cert_resilience", ["cert_resilience_title", "pod_network_latency", "pod_network_corruption", "disk_fill", "pod_delete", "pod_memory_hog", "pod_io_stress", "pod_dns_error"] do |t, args|
  Log.for("verbose").info {  "resilience" } if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
  VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
  # stdout_score("resilience", "Reliability, Resilience, and Availability")
  stdout_score(["resilience", "cert"], "Reliability, Resilience, and Availability")
  case "#{ARGV.join(" ")}" 
  when /cert_resilience/
    stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
  end
end

task "cert_resilience_title" do |_, args|
  puts "Reliability, Resilience, and Availability Tests".colorize(Colorize::ColorRGB.new(0, 255, 255))
end
