# KubeVMI


# How to use

## build 

go build -o bin/manager main.go

## install CRD

make install

## start controller 

make run

## kustomize

kustomize build config/default


# TODO list

1.unit tests 
2.perf
3.format, goreport
