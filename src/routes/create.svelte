<script>
  import {
    user,
    eventCreationInProgress,
    eventCreatedStatus,
  } from "$lib/flow/stores";
  import { authenticate, createWhitelist } from "$lib/flow/actions";

  import { draftWhitelist, theme } from "$lib/stores";
  import { PAGE_TITLE_EXTENSION } from "$lib/constants";
  import { notifications } from '$lib/notifications';


  import LibLoader from "$lib/components/LibLoader.svelte";
  import { onMount } from "svelte";

  let timezone = new Date()
    .toLocaleTimeString("en-us", { timeZoneName: "short" })
    .split(" ")[2];
  /* States related to image upload */
  let ipfsIsReady = false;
  let uploading = false;
  let uploadingPercent = 0;
  let uploadedSuccessfully = false;

  let imagePreview;
  let imagePreviewSrc = null;

  console.log($theme);

  onMount(() => {
    ipfsIsReady = window?.IpfsHttpClient ?? false;
  });

  let uploadToIPFS = async (e) => {
    uploading = true;
    uploadingPercent = 0;

    // imagePreviewSrc = e.target.files[0]
    let file = e.target.files[0];

    function progress(len) {
      uploadingPercent = len / file.size;
    }
    console.log("uploading");

    const client = window.IpfsHttpClient.create({
      host: "ipfs.infura.io",
      port: 5001,
      protocol: "https",
    });

    console.log(file);
    const added = await client.add(file, { progress });
    uploadedSuccessfully = true;
    uploading = false;
    const hash = added.path;
    $draftWhitelist.ipfsHash = hash;
    imagePreviewSrc = `https://ipfs.infura.io/ipfs/${hash}`;
    console.log($draftWhitelist)
  };

  function ipfsReady() {
    console.log("ipfs is ready");
    ipfsIsReady = true;
  }

  let minter = $user?.addr;
  function initCreateWhitelist() {
    createWhitelist($draftWhitelist);
  }
</script>

<svelte:head>
  <title>Create a new Whitelist {PAGE_TITLE_EXTENSION}</title>
</svelte:head>

<LibLoader
  url="https://cdn.jsdelivr.net/npm/ipfs-http-client@56.0.0/index.min.js"
  on:loaded={ipfsReady}
  uniqueId={+new Date()}
/>

<div class="container">
  <article>
    <h1 class="mb-1">Create a new Whitelist</h1>

    <label for="name"
      >Event Name
      <input type="text" id="name" name="name" bind:value={$draftWhitelist.name} />
    </label>

    <label for="name"
      >Event URL
      <input type="text" id="name" name="name" bind:value={$draftWhitelist.url} />
    </label>

    <label for="description"
      >Event Description
      <textarea
        id="description"
        name="description"
        bind:value={$draftWhitelist.description}
      />
    </label>

    {#if ipfsIsReady}
      <label for="image"
        >Event Image
        <input
          aria-busy={!!uploading}
          on:change={(e) => uploadToIPFS(e)}
          type="file"
          id="image"
          name="image"
          accept="image/png, image/gif, image/jpeg"
        />
        {#if uploading}
          <progress value={uploadingPercent * 100} max="100" />
        {/if}

        {#if uploadedSuccessfully}
          <small>✓ Image uploaded successfully to IPFS!</small>
        {/if}
      </label>
    {:else}
      <p>IPFS not loaded</p>
    {/if}

    {#if imagePreviewSrc}
      <img src={imagePreviewSrc} alt="whitelist" />
      <!-- <h3>Preview</h3>
      <Float
        float={{
          eventName: $draftWhitelist.name,
          eventImage: $draftWhitelist.ipfsHash,
          eventMetadata: {
            totalSupply: "SERIAL_NUM",
          },
          eventHost: $user?.addr || "0x0000000000",
        }}
        preview={true}
      />
      <div class="mb-2" /> -->
    {/if}

    <h3 class="mb-1">Configure your Whitelist</h3>

    <h5>Can be changed later.</h5>
    <div class="grid no-break mb-1">
      <button
        class:secondary={!$draftWhitelist.active}
        class="outline"
        on:click={() => ($draftWhitelist.active = true)}
      >
        Active
        <span>Users can register for your whitelist.</span>
      </button>
      <button
        class:secondary={$draftWhitelist.active}
        class="outline"
        on:click={() => ($draftWhitelist.active = false)}
      >
        Not Active
        <span>Users can not register for your whitelist.</span>
      </button>
    </div>

    <h5>Cannot be changed later.</h5>
    <!-- Token Holdings -->
    <div class="grid no-break mb-1">
      <button
        class:secondary={$draftWhitelist.tokenRequirement}
        class="outline"
        on:click={() => ($draftWhitelist.tokenRequirement = false)}
      >
        No Token Requirement
        <span>User does not need to have a certain token.</span>
      </button>
      <button
        class:secondary={!$draftWhitelist.tokenRequirement}
        class="outline"
        on:click={() => ($draftWhitelist.tokenRequirement = true)}
      >
        Token Requirement
        <span>User must have a certain token.</span>
      </button>
    </div>
    {#if $draftWhitelist.tokenRequirement}
      <div class="grid">
        <label for="tokenPath">Enter a public path
          <input
            type="text"
            name="tokenPath"
            bind:value={$draftWhitelist.tokenPath}
            placeholder="/public/flowTokenBalance"
          />
        </label>
        <label for="amount">Enter an amount
          <input
            type="text"
            name="amount"
            bind:value={$draftWhitelist.amount}
            placeholder="40.0"
          />
        </label>
        <label for="tokenPath">Enter an identifier
          <input
            type="text"
            name="tokenPath"
            bind:value={$draftWhitelist.identifier}
            placeholder="A.7e60df042a9c0868.FlowToken.Vault"
          />
        </label>
      </div>
      <hr />
    {/if}

    <footer>
      {#if !$user?.loggedIn}
        <div class="mt-2 mb-2">
          <button class="contrast small-button" on:click={authenticate}>Connect Wallet</button>
        </div>
      {:else if $eventCreationInProgress}
        <button aria-busy="true" disabled>Creating FLOAT</button>
      {:else if $eventCreatedStatus.success}
        <a role="button" class="d-block" href="/account" style="display:block">
          Event created successfully!
        </a>
      {:else if !$eventCreatedStatus.success && $eventCreatedStatus.error}
        <button class="error" disabled>
          {$eventCreatedStatus.error}
        </button>
      {:else if $draftWhitelist.name && $draftWhitelist.ipfsHash && $draftWhitelist.description}
        <button on:click|preventDefault={initCreateWhitelist}>Create Whitelist</button>
      {:else}
        <button disabled on:click|preventDefault={initCreateWhitelist}>Create Whitelist</button>
      {/if}
    </footer>
  </article>
</div>

<style>
  .outline {
    text-align: left;
  }

  .outline span {
    display: block;
    font-size: 0.75rem;
    line-height: 1.2;
    font-weight: 400;
    opacity: 0.6;
  }

  /* .image-preview {
    max-width: 150px;
    height: auto;
  } */

  xmp {
    position: relative;
    width: 100%;
    font-size: 12px;
    padding: 10px;
    overflow: scroll;
    border-radius: 5px;
    color: white;
  }

  .xmp-dark {
    background: rgb(56, 232, 198, 0.25);
  }

  .xmp-light {
    background: rgb(27, 40, 50);
  }

  h5 {
    margin-bottom: 5px;
  }

  .error {
    background-color: red;
    border-color: white;
    color: white;
    opacity: 1;
  }
</style>
