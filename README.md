# Amazon ECR Public credentials helper for Kubernetes

[![Apache License Version 2.0](https://img.shields.io/badge/license-Apache%202-blue?style=flat-square)][license]

[license]: https://github.com/toricls/ecr-public-creds-helper-for-k8s/blob/master/LICENSE

Amazon ECR Public credentials helper for Kubernetes (`ecr-public-creds-helper-for-k8s`, for short) allows pods in your Kubernetes cluster pull and use public container images from Amazon ECR Public registries as authenticated users.

`ecr-public-creds-helper-for-k8s` will run in your cluster as a Kubernetes CronJob. It authenticates against ECR Public and stores the auth token as Kubernetes Secrets within specified namespaces.

Each pod will reference that Kubernetes Secret in its namespace by specifying the `imagePullSecrets` field in PodSpec to reference that Kubernetes Secret. You may also want to patch the `default` service account in each namespace to avoid writing `imagePullSecrets` in all PodSpecs, see comments in the [entrypoint.sh](entrypoint.sh) file for further details.

## Installation

### Step 1

Create a namespace for `ecr-public-creds-helper-for-k8s` to run as a CronJob in your Kubernetes cluster.

### Step 2

Create a service account to allow `ecr-public-creds-helper-for-k8s` to edit Kubernetes secrets.

### Step 3

Create an AWS IAM role to allow `ecr-public-creds-helper-for-k8s` to authenticate against Amazon ECR Public, and map it to the service account which you created in the previous step.

#### With `eksctl`

#### Without `eksctl`

### Step 4

Run `ecr-public-creds-helper-for-k8s` in your Kubernetes cluster.

> NOTE: The following YAML ([cronjob.yaml](cronjob.yaml)) uses the `toricls/aws-kubectl:latest` container image by default, but you may want to create and use your own image instead of the pre-built one. You can create your own image by executing `docker run -t YOUR_IMAGE_NAME .` in the top level of this repository. See also [Dockerfile](Dockerfile).

```shell
$ kubectl apply -f cronjob.yaml
cronjob.batch/ecr-public-creds-helper created
```

### Step 5

Create an initial auth token manually to use it from your pods without waiting the initial cronjob to be started. Note that `ecs-public-creds-helper-for-k8s` refreshes the auth token in every 8 hours by default.

```shell
$ kubectl create job --from=cronjob/ecr-public-creds-helper initial-creds-job
```

## Usage

See [examples/pod.yaml](examples/pod.yaml) to understand how to reference the auth token within your applications :)

## Contribution

1. Fork ([https://github.com/toricls/ecr-public-creds-helper-for-k8s/fork](https://github.com/toricls/ecr-public-creds-helper-for-k8s/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the master branch
1. Create a new Pull Request

## Licence

[Apache License 2.0](LICENSE)

## Author

[Tori](https://github.com/toricls)
