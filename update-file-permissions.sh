# Ensure files can be run in CI

git update-index --chmod=+x ./observe.sh
git update-index --chmod=+x ./run.sh
git update-index --chmod=+x ./build.sh
git update-index --chmod=+x ./install-test-agent.sh
git update-index --chmod=+x ./show-logs.sh

git update-index --chmod=+x ./languages/dotnet/install_ddtrace.sh
git update-index --chmod=+x ./languages/golang/install_ddtrace.sh
git update-index --chmod=+x ./languages/java/install_ddtrace.sh
git update-index --chmod=+x ./languages/nodejs/install_ddtrace.sh
git update-index --chmod=+x ./languages/php/install_ddtrace.sh
git update-index --chmod=+x ./languages/python/install_ddtrace.sh
git update-index --chmod=+x ./languages/ruby/install_ddtrace.sh

sudo chmod 755 ./languages/dotnet/install_ddtrace.sh
sudo chmod 755 ./languages/golang/install_ddtrace.sh
sudo chmod 755 ./languages/java/install_ddtrace.sh
sudo chmod 755 ./languages/nodejs/install_ddtrace.sh
sudo chmod 755 ./languages/php/install_ddtrace.sh
sudo chmod 755 ./languages/python/install_ddtrace.sh
sudo chmod 755 ./languages/ruby/install_ddtrace.sh
