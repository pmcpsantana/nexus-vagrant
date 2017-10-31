#!/bin/bash
set -eux

mkdir -p tmp/use-maven-repository-from-mvn && cd tmp/use-maven-repository-from-mvn

#
# test the maven repository.

# install maven and the java development kit.
sudo apt-get install -y maven
sudo apt-get install -y default-jdk
sudo apt-get install -y xmlstarlet

# setup the user maven configuration to use nexus as a mirror the
# official maven repository.
# see https://help.sonatype.com/display/NXRM3/Maven+Repositories
# see https://maven.apache.org/guides/mini/guide-mirror-settings.html
mkdir -p ~/.m2
cat >~/.m2/settings.xml <<'EOF'
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>alice.doe</username>
      <password>password</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>central</mirrorOf>
      <url>http://localhost:8081/repository/maven-public/</url>
    </mirror>
  </mirrors>
  <profiles>
    <profile>
      <id>nexus</id>
      <repositories>
        <repository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
     <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  <activeProfiles>
    <activeProfile>nexus</activeProfile>
  </activeProfiles>
</settings>
EOF

# test our nexus repository by creating an hello world project, which
# will pull from our nexus repository.
mvn \
  --batch-mode \
  archetype:generate \
  -DgroupId=com.example.helloworld \
  -DartifactId=example-helloworld \
  -DarchetypeArtifactId=maven-archetype-quickstart

# test publishing a package.
pushd example-helloworld
# add the nexus repository to pom.xml.
xmlstarlet ed --inplace -N pom=http://maven.apache.org/POM/4.0.0 \
  --subnode '/pom:project' \
  --type elem \
  --name distributionManagement \
  --value '@@repositories@@' \
  pom.xml
python -c '
xml = open("pom.xml").read().replace("@@repositories@@", """
    <repository>
      <id>nexus</id>
      <name>Releases</name>
      <url>http://localhost:8081/repository/maven-releases</url>
    </repository>
    <snapshotRepository>
      <id>nexus</id>
      <name>Snapshot</name>
      <url>http://localhost:8081/repository/maven-snapshots</url>
    </snapshotRepository>
  """)
open("pom.xml", "w").write(xml)
'
# deploy.
mvn \
  --batch-mode \
  deploy
popd
