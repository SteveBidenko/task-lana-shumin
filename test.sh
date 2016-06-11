#/usr/bin/env bash

cat source.txt | perl handle.pl > _result.txt

diff _target.txt _result.txt
