<script>
  import { checkTokenHolding } from "$lib/flow/actions";

  import { user } from "$lib/flow/stores";

  export let amount;
  export let identifier;
  export let path;
  export let create = false;
  export let id;

  import { draftWhitelist } from "$lib/stores";

  let type = identifier.split(".")[3];
  let token = identifier.split(".")[2];

  const removeToken = () => {
    $draftWhitelist.tokens = $draftWhitelist.tokens.filter(
      (token) => token.id !== id
    );
  };

  // IF THIS IS THE CLAIM PAGE
  let goodToGo = !create
    ? checkTokenHolding(amount, identifier, path, $user.addr)
    : null;
</script>

<article class="module grid">
  <img src="/flowlogo.png" alt="flow logo" />
  <p>Requires {amount} {token}</p>
  {#if create}
    <button class="trash-wrapper" on:click|preventDefault={removeToken}>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        x="0px"
        y="0px"
        width="30"
        height="30"
        viewBox="0 0 30 30"
        style=" fill:#fffff;"
        ><path
          d="M6 8v16c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V8H6zM24 4h-6c0-.6-.4-1-1-1h-4c-.6 0-1 .4-1 1H6C5.4 4 5 4.4 5 5s.4 1 1 1h18c.6 0 1-.4 1-1S24.6 4 24 4z" /></svg>
    </button>
  {:else}
    {#await goodToGo then goodToGo}
      {#if goodToGo}
        <span class="green">&#10003;</span>
      {:else}
        <span class="red">&#10005;</span>
      {/if}
    {/await}
  {/if}
</article>

<style>
  .module {
    padding: 40px 20px;
    justify-items: center;
    align-items: center;
    flex-wrap: wrap;
  }

  .module p {
    margin: 0;
  }
  .module img {
    position: relative;
    min-width: 100px;
    max-width: 100px;
  }

  .trash-wrapper {
    margin: 0px;
    padding: 0px;
    width: 40px;
    height: 40px;
  }
</style>
