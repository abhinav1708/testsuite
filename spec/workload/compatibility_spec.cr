require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/kind_setup.cr"
require "file_utils"
require "sam"

describe "Compatibility" do
  
  before_all do
    result = ShellCmd.run_testsuite("setup")
    result[:status].success?.should be_true
  end

  it "'cni_compatible' should pass if the cnf works with calico and flannel", tags: ["compatibility"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result[:status].success?.should be_true
      retry_limit = 5 
      retries = 1
      until (/PASSED/ =~ result[:output]) || retries > retry_limit
        Log.info { "cni_compatible spec retry: #{retries}" }
        sleep 1.0
        result = ShellCmd.run_testsuite("cni_compatible verbose")
        retries = retries + 1
      end
      Log.info { "Status:  #{result[:output]}" }
      (/(PASSED).*(CNF compatible with both Calico and Cilium)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml")
      result[:status].success?.should be_true
    end
  end

  it "'increase_decrease_capacity' should pass ", tags: ["increase_decrease_capacity"]  do
    begin
      result = ShellCmd.run_testsuite("cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml verbose wait_count=0")
      result[:status].success?.should be_true
      result = ShellCmd.run_testsuite("increase_decrease_capacity verbose")
      result[:status].success?.should be_true
      (/(PASSED).*(Replicas increased to)/ =~ result[:output]).should_not be_nil
    ensure
      result = ShellCmd.run_testsuite("cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml")
    end
  end
end
