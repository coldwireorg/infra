#/bin/bash
hydra migrate sql -e --yes -c /config/hydra.yaml
hydra serve -c /config/hydra.yaml all