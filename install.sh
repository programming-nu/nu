ver=`brew --version`
if [ -n ver ] 
then
  brew install pcre
  brew install libffi
  make
  ./mininush tools/nuke
  ./mininush tools/nuke install
  nuke test
  echo "Nu succesfully installed. Use nush to run nuke."
else
  echo "This installer requires Homebrew."
fi
