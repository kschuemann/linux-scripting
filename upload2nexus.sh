#!/bin/bash

# this script needs a "artifacts" file right next to it.  Create it by using following script in your .m2-folder
#		find -iname "*.pom" -printf "%h\n" > files; find -iname "*.jar" -printf "%h\n" >> files; cat files | sort | uniq -u > artifacts; rm files

NEXUS_USERNAME="admin"
NEXUS_PASSWORD="nexus"
NEXUS_URL="localhost:8081"

cat artifacts | while read i; do

	pompath=$(find $i -name *.pom)
	jarpath=$(find $i -name *.jar)
	
	# extracting metainformations from pom
	groupId=$(echo $pompath | xargs xpath -e 'project/groupId/text()')
	artifactId=$(echo $pompath | xargs xpath -e 'project/artifactId/text()')
	version=$(echo $pompath | xargs xpath -e 'project/version/text()')
	if test -z "$groupId"
	then 
		echo "project-groupId is empty - using parent/groupId"
		groupId=$(echo $pompath | xargs xpath -e 'project/parent/groupId/text()')
	fi
	
	if test -z "$version"
	then 
		echo "project-version of jar-pom is empty - using parent/version"
		version=$(echo $pompath | xargs xpath -e 'project/parent/version/text()')
	fi


	# choosing upload-strategy, preferring jar-upload
	if test -z "$jarpath"
	then
		echo "uploading $artifactId as pom"
		# a 400 error means that the artifactId already exists
		mvn deploy:deploy-file \
		 -DgroupId=$groupId \
		 -DartifactId=$artifactId \
		 -Dversion=$version \
		 -Dpackaging=pom \
		 -Dfile=$pompath \
		 -Durl="http://${NEXUS_USERNAME}:${NEXUS_PASSWORD}@${NEXUS_URL}/repository/maven-releases/"
		echo "uploading $pompath with groupId: $groupId; artifactId: $artifactId; version: $version"
	else 
		echo "uploading $artifactId as jar"
		# a 400 error means that the artifactId already exists
		mvn deploy:deploy-file \
		 -DgroupId=$groupId \
		 -DartifactId=$artifactId \
		 -Dversion=$version \
		 -Dpackaging=jar \
		 -DgeneratePom=true \
		 -Dfile=$jarpath \
		 -Durl="http://${NEXUS_USERNAME}:${NEXUS_PASSWORD}@${NEXUS_URL}/repository/maven-releases"		
		echo "uploading $jarpath with groupId: $groupId; artifactId: $artifactId; version: $version"
	fi 
  
done 

echo 'done uploading artifacts'