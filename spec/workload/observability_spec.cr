require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/fluentbit.cr"
require "../../src/tasks/jaeger_setup.cr"

describe "Observability" do
  before_all do
    `./cnf-testsuite setup`
    $?.success?.should be_true
  end

  it "'log_output' should pass with a cnf that outputs logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/(PASSED).*(Resources output logs to stdout and stderr)/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    end
  end

  it "'log_output' should fail with a cnf that does not output logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/(FAILED).*(Resources do not output logs to stdout and stderr)/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
    end
  end

  it "'prometheus_traffic' should pass if there is prometheus traffic", tags: ["observability"] do
    ShellCmd.run("./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml", "spec_sample_setup", force_output: true)
    helm = Helm::BinarySingleton.helm

    Log.info { "Add prometheus helm repo" }
    ShellCmd.run("#{helm} repo add prometheus-community https://prometheus-community.github.io/helm-charts", "helm_repo_add_prometheus", force_output: true)

    Log.info { "Installing prometheus server" }
    install_cmd = "#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus"
    ShellCmd.run(install_cmd, "helm_install_prometheus", force_output: true)

    KubectlClient::Get.wait_for_install("prometheus-server")
    ShellCmd.run("kubectl describe deployment prometheus-server", "k8s_describe_prometheus", force_output: true)

    test_result = ShellCmd.run("./cnf-testsuite prometheus_traffic", "run_test_cmd", force_output: true)
    (/(PASSED).*(Your cnf is sending prometheus traffic)/ =~ test_result[:output]).should_not be_nil
  ensure
    ShellCmd.run("./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml", "spec_sample_cleaup")
    result = ShellCmd.run("#{helm} delete prometheus", "helm_delete_prometheus")
    result[:status].success?.should be_true
  end

  it "'prometheus_traffic' should skip if there is no prometheus installed", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      helm = Helm::BinarySingleton.helm
      resp = `#{helm} delete prometheus`
      LOGGING.info resp

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/(SKIPPED).*(Prometheus server not found)/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  end

  it "'prometheus_traffic' should fail if the cnf is not registered with prometheus", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      Log.info { "Installing prometheus server" }
      helm = Helm::BinarySingleton.helm
      LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
      # resp = `#{helm} install prometheus prometheus-community/prometheus`
      resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("prometheus-server")
      LOGGING.info `kubectl describe deployment prometheus-server`
      #todo logging on prometheus pod

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/(FAILED).*(Your cnf is not sending prometheus traffic)/ =~ response_s).should_not be_nil
  ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      resp = `#{helm} delete prometheus`
      LOGGING.info resp
      $?.success?.should be_true
  end

  it "'open_metrics' should fail if there is not a valid open metrics response from the cnf", tags: ["observability"] do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml`
    LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
    Log.info { "Installing prometheus server" }
    helm = Helm::BinarySingleton.helm
    # resp = `#{helm} install prometheus prometheus-community/prometheus`
    resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
    LOGGING.info resp
    KubectlClient::Get.wait_for_install("prometheus-server")
    LOGGING.info `kubectl describe deployment prometheus-server`
    #todo logging on prometheus pod

    response_s = `./cnf-testsuite open_metrics`
    LOGGING.info response_s
    (/(FAILED).*(Your cnf's metrics traffic is not OpenMetrics compatible)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-prom-pod-discovery/cnf-testsuite.yml`
    resp = `#{helm} delete prometheus`
    LOGGING.info resp
    $?.success?.should be_true
  end

  it "'open_metrics' should pass if there is a valid open metrics response from the cnf", tags: ["observability"] do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-openmetrics/cnf-testsuite.yml`
    LOGGING.info `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
    LOGGING.info "Installing prometheus server"
    helm = Helm::BinarySingleton.helm
    # resp = `#{helm} install prometheus prometheus-community/prometheus`
    resp = `#{helm} install --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false prometheus prometheus-community/prometheus`
    LOGGING.info resp
    KubectlClient::Get.wait_for_install("prometheus-server")
    LOGGING.info `kubectl describe deployment prometheus-server`
    #todo logging on prometheus pod

    response_s = `./cnf-testsuite open_metrics`
    LOGGING.info response_s
    (/(PASSED).*(Your cnf's metrics traffic is OpenMetrics compatible)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-openmetrics/cnf-testsuite.yml`
    resp = `#{helm} delete prometheus`
    LOGGING.info resp
    $?.success?.should be_true
  end

  #09/27/23 fluentd/fluentd seems to be failing upstream.  bitnami/fluentd works
  # it "'routed_logs' should pass if cnfs logs are captured by fluentd", tags: ["observability"] do
  #   LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  #   resp = `./cnf-testsuite install_fluentd`
  #   LOGGING.info resp
  #   response_s = `./cnf-testsuite routed_logs`
  #   LOGGING.info response_s
  #   (/PASSED: Your cnf's logs are being captured/ =~ response_s).should_not be_nil
  # ensure
  #   LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  #   resp = `./cnf-testsuite uninstall_fluentd`
  #   LOGGING.info resp
  #   $?.success?.should be_true
  # end

  it "'routed_logs' should pass if cnfs logs are captured by fluentd bitnami", tags: ["observability"] do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    resp = `./cnf-testsuite install_fluentdbitnami`
    LOGGING.info resp
    response_s = `./cnf-testsuite routed_logs`
    LOGGING.info response_s
    (/(PASSED).*(Your cnf's logs are being captured)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    resp = `./cnf-testsuite uninstall_fluentdbitnami`
    LOGGING.info resp
    $?.success?.should be_true
  end

  it "'routed_logs' should pass if cnfs logs are captured by fluentbit", tags: ["observability"] do
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-fluentbit`
    FluentBit.install
    response_s = `./cnf-testsuite routed_logs`
    LOGGING.info response_s
    (/(PASSED).*(Your cnf's logs are being captured)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-fluentbit`
    FluentBit.uninstall
    $?.success?.should be_true
  end

  it "'routed_logs' should fail if cnfs logs are not captured", tags: ["observability"] do
  
    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    # resp = `./cnf-testsuite install_fluentd`
    Helm.helm_repo_add("bitnami","oci://registry-1.docker.io/bitnamicharts")
    #todo  #helm install --values ./override.yml fluentd ./fluentd
    Helm.install("--values ./spec/fixtures/fluentd-values-bad.yml -n #{TESTSUITE_NAMESPACE} fluentd bitnami/fluentd")
    Log.info {"Installing FluentD daemonset "}
    KubectlClient::Get.resource_wait_for_install("Daemonset", "fluentd", namespace: TESTSUITE_NAMESPACE)

    response_s = `./cnf-testsuite routed_logs`
    LOGGING.info response_s
    (/(FAILED).*(Your cnf's logs are not being captured)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    resp = `./cnf-testsuite uninstall_fluentd`
    LOGGING.info resp
    $?.success?.should be_true
  end

  it "'tracing' should fail if tracing is not used", tags: ["observability_jaeger_fail"] do
    Log.info {"Installing Jaeger "}
    JaegerManager.install

    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    response_s = `./cnf-testsuite tracing`
    LOGGING.info response_s
    (/(FAILED).*(Tracing not used)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    JaegerManager.uninstall
    KubectlClient::Get.resource_wait_for_uninstall("Statefulset", "jaeger-cassandra")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_uninstall("Daemonset", "jaeger-agent")
  end

  it "'tracing' should pass if tracing is used", tags: ["observability_jaeger_pass"] do
    Log.info {"Installing Jaeger "}
    JaegerManager.install

    LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-tracing/cnf-testsuite.yml`
    response_s = `./cnf-testsuite tracing`
    LOGGING.info response_s
    (/(PASSED).*(Tracing used)/ =~ response_s).should_not be_nil
  ensure
    LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-tracing/cnf-testsuite.yml`
    JaegerManager.uninstall
    KubectlClient::Get.resource_wait_for_uninstall("Statefulset", "jaeger-cassandra")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-collector")
    KubectlClient::Get.resource_wait_for_uninstall("Deployment", "jaeger-query")
    KubectlClient::Get.resource_wait_for_uninstall("Daemonset", "jaeger-agent")
  end

end
