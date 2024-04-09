# VPP IP Forwader Pipeline Service Chain (from the CNF Testbed)

Upstream: https://github.com/cncf/cnf-testbed/tree/master/examples/use_case/3c2n-csp

Description:  Pipeline Service Chain using  3 chains of 2 CNFs (per chain)

This example installs the pipeline service chain example on a kubernetes worker node. All nodes are connected using Memif interfaces, with the chain endpoints connecting to the host vSwitch (VPP) while the intermediate connections are done directly between nodes.

Description:
- Layer 3 packet forwarding
- Based on the fd.io VPP project
- Uses DPDK
- memif interfaces

# Prerequistes
### Install helm version 3

### Automated installation
Run cnf-testsuite setup 
```
export KUBECONFIG=$(pwd)/<YourKubeConf> ; ./cnf-testsuite setup
```

Setup and deploy  service chain
```
export KUBECONFIG=$(pwd)/admin.conf ; ./cnf-testsuite example_cnf_setup example-cnf-path=example-cnfs/vpp-3c2n-csp-use-case/cnf-testsuite.yml
```

### Testing
Run the test suite: `export KUBECONFIG=$(pwd)/admin.conf ; ./cnf-testsuite all`

### Automated cleanup
```
export KUBECONFIG=$(pwd)/admin.conf ; ./cnf-testsuite example_cnf_cleanup example-cnf-path=example-cnfs/vpp-3c2n-csp-use-case/cnf-testsuite.yml
```

### Manual installation
1. Install helm version 3
1. Make the cnfs/vpp-3c2n-csp-use-case diretory 
1. If you are testing the cnf source, clone the source into the cnfs/vpp-3c2n-csp-use-case directory
1. Copy the cnf-testsuite.yml into the cnfs/vpp-3c2n-csp-use-case directory
1. Deploy the service chain using helm: `helm install vpp-3c2n-csp-use-case cnfs/csp`
1. Wait for the installation to finish (all pods are ready)
1. Run the test suite: `export KUBECONFIG=$(pwd)/admin.conf ; ./cnf-testsuite all`
  
