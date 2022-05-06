With vault, running a service change a little bit

1. You need to generate a token with the policy for this service: `vault token create -policy <policy> -period 8h -orphan`
2. Vault should return a token
3. Run the service with the token: `nomad job run -vault-token <token> <service>.hcl`