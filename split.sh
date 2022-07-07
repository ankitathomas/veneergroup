#!/bin/bash

version=4.10

pkgs="$(cat community-operator-index-$version.yaml | yq eval 'select( .schema == "olm.package" )' - )"

for i in $(echo "$pkgs" | yq eval '.name'  - | grep -v '\---') ; do 
	mkdir -p $version/$i; 
	echo "$pkgs" | yq eval 'select(.name == "'"$i"'")' - | tee $version/$i/package.yaml 
	channels="$(cat community-operator-index-$version.yaml | yq eval 'select( .schema == "olm.channel" ) | select(.package == "'"$i"'") ' - )"
	for j in $(echo "$channels" | yq eval '.name'  - | grep -v '\---') ; do
		echo "$channels" | yq eval 'select(.name == "'"$j"'")' - | tee $version/$i/$j.channel.yaml
	done
	bundles="$(cat community-operator-index-$version.yaml | yq eval 'select( .schema == "olm.bundle" ) | select(.package == "'"$i"'") ' - )"
	for j in $(echo "$bundles" | yq eval '.name'  - | grep -v '\---') ; do
		echo "$bundles" | yq eval 'select(.name == "'"$j"'")' - | tee $version/$i/$j.bundle.yaml
	done
done
