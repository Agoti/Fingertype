#!/bin/bash
reset(){
    echo "Resetting..."
    rm -rf result/*
    mkdir result/{input,match,process,register}
    mkdir result/{register_txt,input_txt}
    mkdir result/process/{input,register}
    echo "Done"
}
