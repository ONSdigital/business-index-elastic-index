# business-index-elastic-index

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](./LICENSE)

This repository holds the `Jenkinsfile` used for the creation of an ElasticSearch index and data load, for use by the `business-index-api`. 

Scripts that are relevant to the `business-index-api`, such as `index_exists.sh` and `create_index.sh` exist in [business-index-api/conf/scripts](https://github.com/ONSdigital/business-index-api/tree/master/conf/scripts), all other scripts exist within [./scripts](https://github.com/ONSdigital/business-index-elastic-index/tree/master/scripts).

The index definition for the ElasticSearch index can be found in [business-index-api/conf/index.json](https://github.com/ONSdigital/business-index-api/blob/master/conf/index.json).

### Table of Contents
**[1. Jenkinsfile Steps](#jenkinsfile-steps)**<br>
**[2. Shell Script Linting](#shell-script-linting)**<br>
**[3. License](#license)**<br>

## Jenkinsfile Steps

### Environment

When defining the variables which will be available throughout the `Jenkinsfile`, the index name is generated using the `ENVIRONMENT` build parameter and the current date, in `ddMMyyyy-HHmmss` format. E.g. `bi-${ENVIRONMENT}-ddMMyyyy-HHmmss` -> `bi-dev-01112018-130248`.

### Checkout

This repository is automatically cloned, however we have to also clone the `business-index-api` so that we can access the shell scripts and index definition.

### Index Exists

The `index_exists.sh` script is called, which will fail the pipeline if an index with the name that was just generated does exist.

### Create Index

The `create_index.sh` script is called, which will create the ElasticSearch index using the name we generated along with the index definition from the `business-index-api`.

### Trigger Oozie Job

Firstly, environment specific configuration is retrieved from Gitlab, before the `trigger_oozie_job.sh` script is called, which will replace the `${INDEX_NAME}` variable within the `job.properties` file, before `scp`-ing the `job.properties` file onto the server. The Oozie job is then triggered over `ssh`.

### Alias Index

Once the above stage is complete, an index will be present in ElasticSearch with some data. The user interfaces gets data from ElasticSearch by going to the alias `bi-dev/test/beta`, so the index that we created and loaded data into needs to be aliased to `bi-dev/test/beta`, which also involves de-aliasing the index that is currently aliased.

## Shell Script Linting

To enable shell script linting in VSCode, install `shellcheck` using `brew`.

```shell
brew install shellcheck
```

Then install the [shellcheck](https://github.com/timonwong/vscode-shellcheck) extension in VSCode.

## License

Copyright ©‎ 2018, Office for National Statistics (https://www.ons.gov.uk)

Released under MIT license, see [LICENSE](./LICENSE) for details.