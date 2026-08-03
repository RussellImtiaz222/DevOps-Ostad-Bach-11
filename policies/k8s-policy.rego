"""
OPA Policy as Code - Kubernetes resource validation.
Enforces security and resource management policies.
"""

# docker.rego - Disallow latest Docker tags
package docker

deny[msg] {
    input.image == "latest"
    msg := sprintf("Image must not use 'latest' tag, got: %v", [input.image])
}

deny[msg] {
    endswith(input.image, ":latest")
    msg := sprintf("Image must not use 'latest' tag, got: %v", [input.image])
}

# kubernetes.rego - Require resource limits in Kubernetes
package kubernetes

deny[msg] {
    not input.spec.containers[_].resources.limits
    msg := "Container must have resource limits defined"
}

deny[msg] {
    container := input.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%v' must have CPU limit defined", [container.name])
}

deny[msg] {
    container := input.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%v' must have memory limit defined", [container.name])
}

deny[msg] {
    container := input.spec.containers[_]
    not container.resources.requests
    msg := sprintf("Container '%v' must have resource requests defined", [container.name])
}

# Warn about privileged containers
warn[msg] {
    input.spec.containers[_].securityContext.privileged
    msg := "Running containers in privileged mode is not recommended"
}

# Require security context
deny[msg] {
    not input.spec.containers[_].securityContext
    msg := "Security context must be defined for containers"
}
