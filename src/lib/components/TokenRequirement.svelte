<script>
  import { notifications } from "$lib/notifications";

  import { draftWhitelist } from "$lib/stores";
  import Module from "./Module.svelte";

  let totalSupply = 0;
  let tokenPath = "";
  let amount = "";
  let identifier = "";

  const addNewToken = () => {
    let correct = checkInputs();
    if (!correct) {
      return;
    }
    $draftWhitelist.tokens = [
      ...$draftWhitelist.tokens,
      { tokenPath, amount, identifier, id: totalSupply },
    ];
    totalSupply = totalSupply + 1;
    tokenPath = "";
    amount = "";
    identifier = "";
  };

  function checkInputs() {
    let errorArray = [];

    let fours = identifier.split(".");
    if (fours[0] !== "A" || fours[1].slice(0, 2) === "0x") {
      errorArray.push(
        "Identifier must have format: A.7e60df042a9c0868.FlowToken.Vault"
      );
    }
    if (amount === "") {
      errorArray.push("Amount must be specified.");
    }
    if (tokenPath.slice(0, 8) !== "/public/") {
      errorArray.push("Public path must have format: /public/pathToVault");
    }

    if (errorArray.length > 0) {
      notifications.info(errorArray[0]);
      return false;
    } else {
      return true;
    }
  }
</script>

<!-- Token Holdings -->
<div class="grid no-break mb-1">
  <button
    class:secondary={$draftWhitelist.tokenRequirement}
    class="toggle outline"
    on:click={() => ($draftWhitelist.tokenRequirement = false)}>
    No Tokens
    <span>User does not need to own any tokens.</span>
  </button>

  <button
    class:secondary={!$draftWhitelist.tokenRequirement}
    class="toggle outline"
    on:click={() => ($draftWhitelist.tokenRequirement = true)}>
    Token Requirement
    <span>User must have a certain amount of tokens.</span>
  </button>
</div>

{#if $draftWhitelist.tokenRequirement}
  <label for="amount"
    >Enter the amount of tokens the user must hold.
    <input type="text" name="amount" bind:value={amount} placeholder="40.0" />
  </label>
  <div class="premodules grid">
    <button
      class="flow"
      on:click={() => {
        tokenPath = "/public/flowTokenBalance";
        identifier = "A.7e60df042a9c0868.FlowToken.Vault";
        addNewToken();
      }}><img src="/flowlogo.png" alt="flow" />Add Flow Token</button>

    <button
      class="flow"
      on:click={() => {
        tokenPath = "/public/flowTokenBalance";
        identifier = "A.7e60df042a9c0868.FlowToken.Vault";
        addNewToken();
      }}><img src="/flowlogo.png" alt="flow" />Add FUSD</button>
  </div>
  <article class="custom">
    <h3>Add your own custom token</h3>
    <div class="token-req grid">
      <label for="tokenPath"
        >Enter a public path
        <input
          type="text"
          name="tokenPath"
          bind:value={tokenPath}
          placeholder="/public/flowTokenBalance" />
      </label>
      <label for="tokenPath"
        >Enter an identifier
        <input
          type="text"
          name="tokenPath"
          bind:value={identifier}
          placeholder="A.7e60df042a9c0868.FlowToken.Vault" />
      </label>
      <button class="check-wrapper" on:click|preventDefault={addNewToken}>
        <span>&#10003;</span>
      </button>
    </div>
  </article>
  <hr />

  <!-- Look through the solidified token modules -->
  <h2>Activated modules:</h2>
  <div class="modules grid">
    {#each $draftWhitelist.tokens as token (token.id)}
      <Module
        amount={token.amount}
        identifier={token.identifier}
        create={true}
        id={token.id} />
    {/each}
  </div>
{/if}

<style>
  .modules.grid {
    grid-template-columns: repeat(2, 1fr);
    text-align: center;
  }

  .grid.token-req {
    grid-template-columns: 1fr 1fr 40px;
    align-items: center;
  }

  .custom {
    margin-top: 10px;
    border: 1px solid white;
  }

  .custom h3 {
    position: relative;
    top: -30px;
  }

  .outline.toggle {
    text-align: left;
  }
  .outline span {
    display: block;
    font-size: 0.75rem;
    line-height: 1.2;
    font-weight: 400;
    opacity: 0.6;
  }

  .check-wrapper {
    margin: 0px;
    padding: 0px;
    width: 40px;
    height: 40px;
  }

  .premodules {
    grid-template-columns: repeat(2, 1fr);
  }

  .premodules img {
    max-width: 100px;
  }

  .premodules .flow {
    background-color: #04ee8a;
    display: flex;
    align-items: center;
    border-color: white;
  }
</style>
