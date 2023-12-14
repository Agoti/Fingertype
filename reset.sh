#!/bin/bash
reset(){
    echo "Resetting..."
    rm -rf result/*
    mkdir result/{input,match,process,register}
    mkdir result/process/{input,register}
    echo "Done"
}
