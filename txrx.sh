#!/usr/bin/env bash

set -o nounset

up_rx ()
{
    TXB=$(</sys/class/net/wlp3s0/statistics/tx_bytes)
    sleep 2
    TXBN=$(</sys/class/net/wlp3s0/statistics/tx_bytes)
    TXDIF=$(echo $((TXBN - TXB)))
    printf "$((TXDIF / 1024 / 2))\n"
}

down_tx ()
{
    RXB=$(</sys/class/net/wlp3s0/statistics/rx_bytes)
    sleep 2
    RXBN=$(</sys/class/net/wlp3s0/statistics/rx_bytes)
    RXDIF=$(echo $((RXBN - RXB)) )
    printf "$((RXDIF / 1024 / 2))\n"
}

up_rx
down_tx
