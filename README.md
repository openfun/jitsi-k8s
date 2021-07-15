# Jitsi-k8s, a scalable Jitsi deployment for Kubernetes

## Overview

The goal of this project is to deploy a scalable [Jitsi](https://github.com/jitsi/jitsi-meet)
infrastructure on a Kubernetes cluster.

In its current state, this project only allows to deploy the "Jibri" component.

## Architecture

This repository is composed of two parts:

 - A [Terraform](https://www.terraform.io/) project, whose goal is to deploy a ready-to-use Kubernetes
   cluster. It also installs some Helm packages to enable required features (e.g. custom metrics)

 - A [kustomize](https://kustomize.io/) project, in which are defined the resources to deploy on
   the Kubernetes cluster.


We made the following (opinionated) choices, but the project can be easily adapted to choose alternatives options :

- We use [Scaleway](https://www.scaleway.com/) as a cloud provider, to provision the Kubernetes cluster.
- The Terraform state is stored in an [Openstack Swift](https://docs.openstack.org/swift/latest/) bucket.


## Getting started

### Terraform configuration

#### 1.1 Configure Openstack credentials

The Terraform state is stored in an Openstack Swift bucket.
So, you need to provide the required environment variables to authenticate against Openstack.

Execute the following command to initialize the `env.d/terraform` file:

```
make env.d/terraform
```

Then, edit this file (`env.d/terraform`) and define the `OS_*` variables according to your Openstack environment.

Note: if you use OVH as Swift bucket provider, you can get these values in the Horizon interface, by clicking on the «Openstack RC File v3» in the upper-right menu.

#### 1.2 Create the Terraform state bucket

Important: if your team has already initialized the state bucket, skip this part and go to chapter `1.3`

To create the Swift bucket required to store the Terraform state, there is a
Terraform project dedicated to this in the directory `terraform/create_state_bucket`.

To create the state bucket, you need to execute the following commands:

```bin/state init```

and then:

```bin/state apply```

#### 1.3 Initialize Terraform

Execute the following command to initialize Terraform with the configured state.

```bin/terraform init```

#### 1.4. Scaleway credentials

We use Scaleway to provision the Kubernetes cluster. You need to set your Scaleway API credentials in environment variables.

##### 1.4a : single environment

If you intend to deploy this project on a single environment, you can set the following variables in `env.d/terraform` :

- `SCW_DEFAULT_PROJECT_ID` : your scaleway project ID
- `SCW_ACCESS_KEY` : your Scaleway API access key
- `SCW_SECRET_KEY` : your Scaleway API secret key

##### 1.4b : multiple environments (recommended)

In most cases, you'll deploy this project on multiple environments (e.g. : preprod, production).

You'll have to create a Scaleway project for each of these environments.
And each environment will have its own Terraform workspace.

To create a workspace named `production`, you can use the following command:

```bin/terraform workspace new production```

To list the available workspaces:

```bin/terraform workspace list```

To change the current workspace:

```bin/activate```

Here is a sample configuration for 2 environments (`production` and `preprod`) in `env.d/terraform`:

```
TF_VAR_scaleway_access_key={ production = "access_key_A", preprod = "access_key_B"}
TF_VAR_scaleway_secret_key={ production = "secret_key_A", preprod = "secret_key_B"}
TF_VAR_scaleway_project_id={ production = "project_A", preprod = "project_B"}
```

#### 1.5 : customize configuration

Look at the variables defined in `terraform/variables.tf`.
You can customize them by environment, just like we did in step `1.4b`.

#### 1.5 : deploy :rocket:

Execute the following command to see what resources will be deployed:

```bin/terraform plan```

And when you are ready to deploy it:

```bin/terraform apply```


### Kubernetes

Once your kubernetes cluster is deployed, you can interact with it with the command `bin/kubectl`.

If you work with multiple environments, don't forget to select the right one by executing `bin/activate`.


To initialize an environment, you can execute `make bootstrap`.
It will generate 2 files :

- `env.d/jitsi.env-<environment-name>`
- `env.d/jitsi-secrets.env-<environment-name>`

You should customize these Jitsi related variables with your own requirements.


All Kubernetes resources definition are stored in the `k8s` directory, using the [Kustomize](https://kustomize.io/) template syntax.



To generate the configuration to deploy, you can execute :
```make k8s-build-config```

And to actually deploy it, you can execute:
```make k8s-apply-config```
