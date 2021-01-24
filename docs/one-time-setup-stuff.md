# one-time-setup-stuff

There are a few important pregame steps:

1 - Install some programs: `brew install aws-iam-authenticator kubernetes-cli`

Also, take some time to install [ktx]; it should only take a moment.

2 - Set your project environment variables in build.env

3 - Source-in those variables:

`source scripts/setup/build.env stage`

4 - Create the project bucket

`scripts/setup/create-project-bucket.sh`

5 - Check the contents of the `backend.hcl` and create a DynamoDB table with this name:

```bash
$ cat backend.hcl 
/*
  -----------------------------------------------------------------------------
                           CENTRALIZED HOME FOR STATE
                           inerpolations NOT allowed
  -----------------------------------------------------------------------------
*/
dynamodb_table  = "tf-state-pipes-lock"
bucket          = "tf-state-pipes"
key             = "network/stage"
region          = "us-west-2"
encrypt         = true
```

You should now be clear for a `make tf-init`.

[ktx]:https://github.com/heptiolabs/ktx
