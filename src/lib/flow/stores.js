import { writable, get } from 'svelte/store';

export const user = writable(null);
export const getUser = get(user);
export const transactionStatus = writable(null);
export const txId = writable(null);
export const transactionInProgress = writable(false);

export const registeringInProgress = writable(false);
export const registeringStatus = writable(false);

export const eventCreationInProgress = writable(false);
export const eventCreatedStatus = writable(false);