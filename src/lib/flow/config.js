import {config} from "@samatech/onflow-fcl-esm";

config({
  "accessNode.api": import.meta.env.VITE_ACCESS_NODE_API,
  "discovery.wallet": import.meta.env.VITE_DISCOVERY_WALLET,
  "0xPM": "0x41e6fe5160fa06e9", //import.meta.env.VITE_FLOAT_ADDRESS,
  "0xCORE": import.meta.env.VITE_CORE_CONTRACTS_ADDRESS
})