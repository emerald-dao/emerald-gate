<script>
  import CheckAddress from "$lib/components/CheckAddress.svelte";
  import { PAGE_TITLE_EXTENSION } from "$lib/constants";
  import { setupFUSDVault } from "$lib/flow/actions";
</script>

<svelte:head>
  <title>Home {PAGE_TITLE_EXTENSION}</title>
</svelte:head>

<div class="grid">
  <article>
    <a href="/create">Create</a>
    <button on:click={setupFUSDVault}>Setup FUSD Vault</button>
  </article>
</div>

<CheckAddress />

<style>
  a {
    text-align: center;
  }
</style>
