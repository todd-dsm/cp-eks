# Observability

Each suite (Datadog, Honeycomb, AppD, Splunk) is driven by a `values.yaml` file; those files live here. Effectively, we take the default values file ([example]) and make these modifications:

## Datadog

### Enable logs agent and provide custom configs

 * logs.enabled: `false -> true`
 * logs.containerCollectAll: `false -> true`

### Enable apm agent and provide custom configs

 * apm.enabled: `false -> true`
   
### Enable systemProbe agent and provide custom configs

 * systemProbe.enabled: `false -> true` (must add `enabled:` line)

### Enable process agent and provide custom configs

 * processAgent.enabled: `false -> true`
 * processAgent.processCollection: `false -> true`

[example]:https://github.com/DataDog/helm-charts/blob/master/charts/datadog/values.yaml
