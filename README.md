# Jitsi-k8s, a scalable Jitsi deployment for Kubernetes

## Overview

The goal of this project is to deploy a scalable [Jitsi](https://github.com/jitsi/jitsi-meet)
infrastructure on a Kubernetes cluster.

## Architecture

This repository is composed of two parts:

 - A [Terraform](https://www.terraform.io/) project, whose goal is to deploy a ready-to-use Kubernetes
   cluster. It also installs some Helm packages to enable required features (e.g. custom metrics)

 - A [kustomize](https://kustomize.io/) project, in which are defined the resources to deploy on
   the Kubernetes cluster.


We made the following (opinionated) choices, but the project can be easily adapted to choose alternative options:

- We use [Scaleway](https://www.scaleway.com/) as a cloud provider, to provision the Kubernetes cluster.
- The Terraform state is stored in an [Openstack Swift](https://docs.openstack.org/swift/latest/) bucket.


## Getting started

### Terraform configuration

#### 1.1 Configure Openstack credentials

The Terraform state is stored in an Openstack Swift bucket.
So, you need to provide the required environment variables to authenticate against Openstack.

Execute the following command to initialize the `env.d/terraform` file:

```
make bootstrap
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

##### 1.4a: single environment

If you intend to deploy this project on a single environment, you can set the following variables in `env.d/terraform`:

- `SCW_DEFAULT_PROJECT_ID`: your scaleway project ID
- `SCW_ACCESS_KEY`: your Scaleway API access key
- `SCW_SECRET_KEY`: your Scaleway API secret key

##### 1.4b: multiple environments (recommended)

In most cases, you'll deploy this project on multiple environments (e.g.: preprod, production).

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

#### 1.5: customize configuration

Look at the variables defined in `terraform/variables.tf`.
You can customize them by environment, just like we did in step `1.4b`.

#### 1.5: deploy :rocket:

Execute the following command to see what resources will be deployed:

```bin/terraform plan```

And when you are ready to deploy it:

```bin/terraform apply```


### Kubernetes

Once your kubernetes cluster is deployed, you can interact with it with the command `bin/kubectl`.

First of all, don't forget to select the right environment one by executing `bin/activate`.

Base Kubernetes resources definition are stored in the `k8s/base` directory, using [Kustomize](https://kustomize.io/).

#### 2.1 Overlay initialization

Each environment should be defined as a Kustomize overlay, inheriting from the base definition.
To generate a Kustomize overlay for your environment, you can execute the following command:

```shell
bin/init-overlay
```

You will be asked for the FQDN (e.g. `jitsi-staging.example.com`) that you will use for this environment.
You will also be asked for an email address that will be used to create a Let's Encrypt issuer account.

After then, your new overlay will be created in the directory `k8s/overlays/<your-environment>/`.
Note that this directory is ignored by git, we'll see later how to move it on a separate repository for team work.

It is ready to use as-is.

If you want to customize it, look at the environment variables defined in the `k8s/base/env` directory to see the default
values and get an overview of what you can change easily.

You can also override Kubernetes resources using [Kustomize](https://kustomize.io/).

#### 2.2 DNS entry

You need to create a DNS `A` entry for the FQDN that you specified in the previous section.
It should point to the public IP reserved by terraform, you can get it by executing the
following command:

```shell
bin/terraform output ingress_public_address
```

#### 2.3 Deploy :rocket:


To generate the configuration to deploy, you can execute :
```make k8s-build-config```

And to actually deploy it, you can execute:
```make k8s-apply-config```

## Overlay versioning

You might want to share your overlays with your team and version it on a VCS.
You can do this, you just have to provide a OVERLAYS_HOME environment variable
containing an absolute path to your overlay directory.

You can either export it as needed, or set it permanently in the
`env.d/kustomize` file.

Example:

```
If you have the following terraform environments:
- production
- staging
- test

You can store your overlays in a directory structure like this:
/tmp/my-overlays
├── production
│   ├── kustomization.yaml
│   └── ...
├── staging
│   ├── kustomization.yaml
│   └── ...
└── test
    ├── kustomization.yaml
    └── ...

And you just have to set this value in `env.d/kustomize`:
OVERLAYS_HOME=/tmp/my-overlays

```

## Adding jwt auth

This project is thought to allow delegating authentication to an external gateway like [jitsi magnify](https://github.com/openfun/jitsi-magnify) which uses JWT tokens to authenticate users. To activate this, you can change variables in the `jitsi-common.env` file of your overlay.  For example, to delegate authentication to [jitsi magnify](https://github.com/openfun/jitsi-magnify), change auth type to jwt, put auth_url to url of your external gateway, and set values for app_id and app_secret that will also be set to the same values in magnify.

## Secrets encryption

If you store your overlays on a shared repository, you might want to encrypt
your .env files that contain sensitive values, like the `jitsi-secrets.env`
that is used to generate a Kubernetes Secret.

There are multiple solutions to solve this problem, as Kustomize is extensible
with its plugin system. If you want to store sensitive values on an external
source (like AWS Secret Manager, Azure Vault or Hashicorp Vault), you can use
the [Secretize plugin](https://github.com/bbl/secretize).

A `GpgSecretGenerator` plugin is bundled with this project. It allows to generate
a Secret from a GPG encrypted file (with a symmetric cipher). You can find an
example of usage within the [example](k8s/overlays/example/) overlay.
You might want to look at these files :
- [kustomization.yaml](k8s/overlays/example/kustomization.yaml) : see the generators section
- [secret-generator.yaml](k8s/overlays/example/secret-generator.yaml) : the generator configuration file
- [secrets.env.gpg](k8s/overlays/example/secrets.env.gpg): the GPG encrypted env file (the passphrase is `example`)  

You just have to provide the passphrase in the `SECRET_GPG_PASSWORD` environment variable when invoking `kustomize`.
