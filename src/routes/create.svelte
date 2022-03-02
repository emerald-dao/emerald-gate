<script>
  import {
    user,
    eventCreationInProgress,
    eventCreatedStatus,
  } from "$lib/flow/stores";
  import { authenticate, createWhitelist } from "$lib/flow/actions";

  import { draftWhitelist, theme } from "$lib/stores";
  import { PAGE_TITLE_EXTENSION } from "$lib/constants";
  import { notifications } from "$lib/notifications";

  import LibLoader from "$lib/components/LibLoader.svelte";
  import { onMount } from "svelte";
  import { destroy_block } from "svelte/internal";
  import TokenRequirement from "$lib/components/TokenRequirement.svelte";

  /* States related to image upload */
  let ipfsIsReady = false;
  let uploading = false;
  let uploadingPercent = 0;
  let uploadedSuccessfully = false;

  let imagePreview;
  let imagePreviewSrc = null;

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
    console.log($draftWhitelist);
  };

  function ipfsReady() {
    console.log("ipfs is ready");
    ipfsIsReady = true;
  }

  let minter = $user?.addr;
  function initCreateWhitelist() {
    let canCreateWhitelist = checkInputs();

    if (!canCreateWhitelist) {
      return;
    }

    createWhitelist($draftWhitelist);
  }

  function checkInputs() {
    let errorArray = [];
    let messageString = "Identifier formatted incorrectly";

    let tokens = $draftWhitelist.tokens;
    tokens.forEach((token) => {
      let identifier = token.identifier;
      let fours = identifier.split(".");
      if (fours[0] !== "A" || fours[1].slice(0, 2) === "0x") {
        errorArray.push(identifier);
      }
    });

    if (errorArray.length > 0) {
      notifications.info(`${messageString}: ${errorArray.join(",")}`);
      return false;
    } else {
      return true;
    }
  }
</script>

<svelte:head>
  <title>Create a new Whitelist {PAGE_TITLE_EXTENSION}</title>
</svelte:head>

<LibLoader
  url="https://cdn.jsdelivr.net/npm/ipfs-http-client@56.0.0/index.min.js"
  on:loaded={ipfsReady}
  uniqueId={+new Date()} />

<div class="container">
  <article>
    <h1 class="mb-1">Create a new Whitelist</h1>

    <label for="name"
      >Event Name
      <input
        type="text"
        id="name"
        name="name"
        bind:value={$draftWhitelist.name} />
    </label>

    <label for="name"
      >Event URL
      <input
        type="text"
        id="name"
        name="name"
        bind:value={$draftWhitelist.url} />
    </label>

    <label for="description"
      >Event Description
      <textarea
        id="description"
        name="description"
        bind:value={$draftWhitelist.description} />
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
          accept="image/png, image/gif, image/jpeg" />
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

    {#if $draftWhitelist.name && $draftWhitelist.description && imagePreviewSrc}
      <article class="whitelist-preview">
        <img src={imagePreviewSrc} alt="whitelist" />
        <div>
          <h2>{$draftWhitelist.name}</h2>
          <p>{$draftWhitelist.description}</p>
        </div>
      </article>
    {/if}

    <h3 class="mb-1">Configure your Whitelist</h3>

    <h5>Can be changed later.</h5>
    <div class="grid no-break mb-1">
      <button
        class:secondary={!$draftWhitelist.active}
        class="outline"
        on:click={() => ($draftWhitelist.active = true)}>
        Active
        <span
          >Users can register for your whitelist and yeah yeah yeah yeah.</span>
      </button>
      <button
        class:secondary={$draftWhitelist.active}
        class="outline"
        on:click={() => ($draftWhitelist.active = false)}>
        Not Active
        <span>Users can not register for your whitelist.</span>
      </button>
    </div>

    <h5>Cannot be changed later.</h5>
    <!-- Put all the different Modules here -->
    <TokenRequirement />

    <footer>
      {#if !$user?.loggedIn}
        <div class="mt-2 mb-2">
          <button class="contrast small-button" on:click={authenticate}
            >Connect Wallet</button>
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
        <button on:click|preventDefault={initCreateWhitelist}
          >Create Whitelist</button>
      {:else}
        <button disabled on:click|preventDefault={initCreateWhitelist}
          >Create Whitelist</button>
      {/if}
    </footer>
  </article>
</div>

<style>
  .whitelist-preview {
    display: flex;
    align-items: center;
    padding-top: 20px;
    padding-bottom: 20px;
  }
  .whitelist-preview img {
    width: 100px;
    padding-right: 20px;
  }

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
