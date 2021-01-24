# cp-eks

A starting point for bootstrapping an EKS structure in AWS with Terraform.

---

## Getting Started

Check the docs for [one-time setup steps].

Source-in the project variables to your environment:

`source build.env <dev|stage|prod>`

`make tf-init`, `make plan` and `make apply`.

## Pre-installed Application Requirements

* aws-iam-authenticator
* awscli
* kubectl
* helm
* Terraform v0.13.5
* ktx (heptio)
