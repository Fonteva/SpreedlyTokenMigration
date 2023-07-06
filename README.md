# SpreedlyTokenMigration

### Package creation commands:

##### to create the package version (beta)
sfdx package version create --package "Spreedly Token Migration" --installation-key-bypass --code-coverage  --wait=2

##### to set the beta package as released:
sfdx package version promote --package 04txxxxxxxxxxxx
