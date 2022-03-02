import { writable } from 'svelte/store';

export const draftWhitelist = writable({
  name: '',
  description: '',
  url: '',
  ipfsHash: '',
  active: true,
  amount: '',
  identifier: '',
  tokenPath: '',
  tokenRequirement: false
});


export const theme = writable(null);

// draftFloat.subscribe((value) => {
//   console.log(value)
// })