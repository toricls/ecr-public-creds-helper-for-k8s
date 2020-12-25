# Amazon ECR "Public" credentials helper for Kubernetes

[![Apache License Version 2.0](https://img.shields.io/badge/license-Apache%202-blue?style=flat-square)][license]

[license]: https://github.com/toricls/ecr-public-creds-helper-for-k8s/blob/master/LICENSE

Amazon ECR "Public" credentials helper for Kubernetes (`ecr-public-creds-helper-for-k8s` for short) allows pods in your Kubernetes cluster pull public container images from [Amazon ECR Public](https://aws.amazon.com/blogs/aws/amazon-ecr-public-a-new-public-container-registry/) registries **as authenticated users** to get the limit upgraded to `10` pulls per second which is `1` for unauthenticated users as described [here](https://docs.aws.amazon.com/AmazonECR/latest/public/public-service-quotas.html) or unlimited bandwidth as described [here](https://aws.amazon.com/ecr/pricing/).

`ecr-public-creds-helper-for-k8s` will run in your cluster as a Kubernetes CronJob every 8 hours by default. It authenticates against ECR Public and stores the auth token as Kubernetes Secrets within namespaces you specified.

Each pod (even on AWS Fargate) will reference that Kubernetes Secret in its namespace by specifying the `imagePullSecrets` field in PodSpec to reference that Kubernetes Secret. You may also want to patch the `default` service account in each namespace to avoid writing `imagePullSecrets` in all PodSpecs, see comments in the [entrypoint.sh](entrypoint.sh) file for further details.

## Installation

### Step 1

Create a namespace for `ecr-public-creds-helper-for-k8s` to run as a CronJob in your Kubernetes cluster.

```shell
$ kubectl apply -f namespace.yaml
namespace/ecr-public-creds-helper created
```

### Step 2

Create a service account to allow `ecr-public-creds-helper-for-k8s` to edit Kubernetes secrets.

```shell
$ kubectl apply -f serviceaccount.yaml
serviceaccount/sa-secrets-editor created
clusterrole.rbac.authorization.k8s.io/secrets-editor created
clusterrolebinding.rbac.authorization.k8s.io/edit-secrets created
```

### Step 3

Create an AWS IAM role to allow `ecr-public-creds-helper-for-k8s` to authenticate against Amazon ECR Public. We use the mechanism called [IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) to map it to the service account which you created in the previous step.

If you have not enabled IRSA in your Kubernetes cluster yet, please follow the [IRSA documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) and/or the [blog post](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) for enabling IRSA for your Kubernetes cluster.

We're going to use `eksctl` here to show the step to create and map the IAM role in EKS cluster, but you can also use the AWS CLI, the AWS management console, CloudFormation, Terraform or whatever you want to use.

```shell
$ export POLICY_ARN=$(aws iam create-policy --policy-name AmazonECRPublicAuthOnlyPolicy --policy-document file://iam-permission.json --query Policy.Arn --output text)
## Make sure you've created the policy successfully
$ echo ${POLICY_ARN}
arn:aws:iam::YOUR_AWS_ACCOUNT_ID:policy/AmazonECRPublicAuthOnlyPolicy

$ export EKS_CLUSTER_NAME=<your-eks-cluster-name-here>

$ eksctl create iamserviceaccount --cluster=${EKS_CLUSTER_NAME} \
    --name=sa-secrets-editor \
    --namespace=ecr-public-creds-helper \
    --attach-policy-arn=${POLICY_ARN} \
    --override-existing-serviceaccounts \
    --approve
```

### Step 4

Run `ecr-public-creds-helper-for-k8s` in your Kubernetes cluster.

> NOTE: The following YAML file ([cronjob.yaml](cronjob.yaml)) uses the `toricls/ecr-public-creds-helper-for-k8s:latest` container image by default, but you may want to create and use your own image instead of the pre-built one. You can create your own image by executing `docker run -t YOUR_IMAGE_NAME .` in the top level of this repository. See also [Dockerfile](Dockerfile).

```shell
$ vim cronjob.yaml # Modify the value of the "TARGET_NAMESPACES" environment variable in line.26 to choose which namespaces you want to use the auth token

$ kubectl apply -f cronjob.yaml
cronjob.batch/ecr-public-creds-helper created
```

### Step 5

Create an initial auth token manually to use it from your pods without waiting the initial cronjob to be started. Note that `ecs-public-creds-helper-for-k8s` refreshes the auth token in every 8 hours by default.

```shell
$ kubectl create job initial-creds-job \
    -n ecr-public-creds-helper \
    --from=cronjob/ecr-public-creds-helper
job.batch/initial-creds-job created

## Check the pod log to make sure it works as expected
$ export POD_NAME=$(kubectl get pods --selector=job-name=initial-creds-job -n ecr-public-creds-helper -o jsonpath='{.items[0].metadata.name}')

$ echo ${POD_NAME}
initial-creds-job-r4fbp # you'll see something like this

$ kubectl logs ${POD_NAME} -n ecr-public-creds-helper
### You'll see the same number of lines as the "TARGET_NAMESPACES" you specified in cronjob.yaml here
secret/ecr-public-token created
secret/ecr-public-token created
secret/ecr-public-token created

$ kubectl delete job initial-creds-job -n ecr-public-creds-helper
job.batch "initial-creds-job" deleted
```

## Use auth tokens in Pods

Now your pod can use the auth token (Kubernetes secret) created by `ecr-public-creds-helper-for-k8s` to pull public container images as an authenticated user from Amazon ECR Public registries.

See [examples/pod.yaml](examples/pod.yaml) to understand how to reference the auth token from your pods like:

```yaml
apiVersion: v1
kind: Pod
# ~ snip ~
spec:
# ~ snip ~
  imagePullSecrets:
  - name: ecr-public-token
# ~ snip ~
```

## Contribution

1. Fork ([https://github.com/toricls/ecr-public-creds-helper-for-k8s/fork](https://github.com/toricls/ecr-public-creds-helper-for-k8s/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the main branch
1. Create a new Pull Request

## Licence

[Apache License 2.0](LICENSE)

## Author

[Tori](https://github.com/toricls)
